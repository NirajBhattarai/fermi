// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {EasyPosm} from "./utils/libraries/EasyPosm.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {FermiHook} from "../src/FermiHook.sol";
import {Fermi3} from "../src/lib/Fermi3.sol";
import {BaseTest} from "./utils/BaseTest.sol";

// @notice Fork test for FermiHook against a forked mainnet.
// Run with: forge test --fork-url <RPC_URL> --match-path test/FermiFork.t.sol
contract FermiForkTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    // Canonical mainnet stablecoins
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    Currency currency0;
    Currency currency1;
    Currency currency2;

    PoolKey poolKey;
    PoolId poolId;

    FermiHook hook;
    IERC20[] tokens;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    function setUp() public {
        deployArtifactsAndLabel();

        // Wrap real forked tokens as Currency (ordered by address)
        address[] memory addrs = new address[](3);
        addrs[0] = USDC;
        addrs[1] = USDT;
        addrs[2] = DAI;
        // Sort ascending for Currency ordering
        if (USDC > USDT) {
            addrs[0] = USDT;
            addrs[1] = USDC;
        }
        if (USDC > DAI) {
            address tmp = addrs[0];
            addrs[0] = DAI;
            addrs[2] = tmp;
        }
        if (USDT > DAI) {
            address tmp = addrs[1];
            addrs[1] = DAI;
            addrs[2] = tmp;
        }

        currency0 = Currency.wrap(addrs[0]);
        currency1 = Currency.wrap(addrs[1]);
        currency2 = Currency.wrap(addrs[2]);

        tokens = new IERC20[](3);
        tokens[0] = IERC20(addrs[0]);
        tokens[1] = IERC20(addrs[1]);
        tokens[2] = IERC20(addrs[2]);

        for (uint256 k; k < 3; k++) {
            tokens[k].approve(address(permit2), type(uint256).max);
            tokens[k].approve(address(swapRouter), type(uint256).max);
            permit2.approve(address(tokens[k]), address(positionManager), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[k]), address(poolManager), type(uint160).max, type(uint48).max);
        }

        address flags = address(
            uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG)
                ^ (0x4444 << 144)
        );
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("FermiHook.sol:FermiHook", constructorArgs, flags);
        hook = FermiHook(flags);

        poolKey = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = poolKey.toId();

        // 3-stable parameters similar to paper preset
        uint256[3] memory w = [uint256(625e15), uint256(3125e14), uint256(625e14)];
        uint256[3] memory b = [uint256(4e17), uint256(4e17), uint256(1e17)];
        vm.prank(address(poolManager));
        hook.initializePool(poolKey, [addrs[0], addrs[1], addrs[2]], Fermi3.Params({w: w, b: b, R: 10e18}), 160e18);

        poolManager.initialize(poolKey, Constants.SQRT_PRICE_1_1);

        tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);
        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            Constants.SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        (tokenId,) = positionManager.mint(
            poolKey,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );
    }

    function testForkHookInitialized() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");
        Fermi3.State memory s = hook.getPoolState(poolId);
        assertApproxEqAbs(s.K, -61000276933285228154, 1e6, "K matches paper");
    }

    function testForkSwapUpdatesHookState() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");

        uint256 amountIn = 1e6; // 1 USDC/USDT (6 decimals)
        BalanceDelta swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp + 300
        });
        assertEq(int256(swapDelta.amount0()), -int256(amountIn));

        Fermi3.State memory s = hook.getPoolState(poolId);
        int256 drift = Fermi3.invariant(s.params, s.V, s.x) - s.K;
        require(drift >= -1e12, "FermiHook: invariant not preserved after swap");
    }

    function testForkSpotAtBalanceIsPar() public view {
        Fermi3.State memory s = hook.getPoolState(poolId);
        uint256 spot = Fermi3.spot(s, 0, 1);
        uint256 diff = spot > 1e18 ? spot - 1e18 : 1e18 - spot;
        require(diff <= 1e9, "spot not at par");
    }
}
