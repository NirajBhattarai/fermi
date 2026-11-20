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

import {FermiHook} from "../src/FermiHook.sol";
import {Fermi3} from "../src/lib/Fermi3.sol";
import {BaseTest} from "./utils/BaseTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

contract FermiHookTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    Currency currency0;
    Currency currency1;
    Currency currency2;

    PoolKey poolKey;
    PoolId poolId;

    FermiHook hook;
    MockERC20[] tokens;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    function setUp() public {
        deployArtifactsAndLabel();

        (currency0, currency1) = deployCurrencyPair();
        currency2 = Currency.wrap(address(new MockERC20("Coin C", "C", 18)));

        tokens = new MockERC20[](3);
        tokens[0] = MockERC20(Currency.unwrap(currency0));
        tokens[1] = MockERC20(Currency.unwrap(currency1));
        tokens[2] = MockERC20(Currency.unwrap(currency2));

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

        uint256[3] memory w = [uint256(625e15), uint256(3125e14), uint256(625e14)];
        uint256[3] memory b = [uint256(4e17), uint256(4e17), uint256(1e17)];
        vm.prank(address(poolManager));
        hook.initializePool(
            poolKey,
            [address(tokens[0]), address(tokens[1]), address(tokens[2])],
            Fermi3.Params({w: w, b: b, R: 10e18}),
            160e18
        );

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

    function testHookInitialized() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");
        Fermi3.State memory s = hook.getPoolState(poolId);
        assertApproxEqAbs(s.K, -61000276933285228154, 1e6, "K matches paper");
    }

    function testSpotAtBalanceIsPar() public view {
        Fermi3.State memory s = hook.getPoolState(poolId);
        uint256 spot = Fermi3.spot(s, 0, 1);
        uint256 diff = spot > 1e18 ? spot - 1e18 : 1e18 - spot;
        require(diff <= 1e9, "spot not at par");
    }

    function testSwapUpdatesHookState() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");

        uint256 amountIn = 1e18;
        BalanceDelta swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp + 1
        });
        assertEq(int256(swapDelta.amount0()), -int256(amountIn));

        Fermi3.State memory s = hook.getPoolState(poolId);
        int256 drift = Fermi3.invariant(s.params, s.V, s.x) - s.K;
        require(drift >= -1e12, "FermiHook: invariant not preserved after swap");
    }

    function testSwapReverseDirection() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");

        // Swap coin1 -> coin0 (reverse of setup ordering)
        uint256 amountIn = 1e18;
        BalanceDelta swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: false,
            poolKey: poolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp + 1
        });
        assertEq(int256(swapDelta.amount1()), -int256(amountIn));

        Fermi3.State memory s = hook.getPoolState(poolId);
        int256 drift = Fermi3.invariant(s.params, s.V, s.x) - s.K;
        require(drift >= -1e12, "FermiHook: invariant not preserved after reverse swap");
    }

    function testSwapExactOut() public {
        require(hook.isPoolInitialized(poolId), "FermiHook: pool not initialized");

        // Exact-out: receive 5e17 of token1, pay token0 as needed
        uint256 amountOut = 5e17;
        BalanceDelta swapDelta = swapRouter.swapTokensForExactTokens(
            amountOut,
            1e18, // amountInMax
            true, // zeroForOne: token0 -> token1
            poolKey,
            Constants.ZERO_BYTES,
            address(this),
            block.timestamp + 1
        );

        assertEq(int256(swapDelta.amount1()), int256(amountOut));

        Fermi3.State memory post = hook.getPoolState(poolId);
        int256 drift = Fermi3.invariant(post.params, post.V, post.x) - post.K;
        require(drift >= -1e12, "FermiHook: invariant not preserved after exact-out swap");
    }
}
