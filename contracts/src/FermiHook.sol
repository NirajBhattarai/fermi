// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Fermi3} from "./lib/Fermi3.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

contract FermiHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    struct Pool {
        address[3] tokens;
        Fermi3.Params params;
        uint256 V;
        bool initialized;
    }

    mapping(PoolId => Pool) public pools;
    mapping(PoolId => Fermi3.State) public states;

    function isPoolInitialized(PoolId id) public view returns (bool) {
        return pools[id].initialized;
    }

    function getPoolState(PoolId id) public view returns (Fermi3.State memory) {
        return states[id];
    }

    function getPoolParams(PoolId id) public view returns (Fermi3.Params memory) {
        return pools[id].params;
    }

    error NotInitialized();
    error UnknownToken();

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function initializePool(PoolKey calldata key, address[3] calldata tokens, Fermi3.Params memory params, uint256 V)
        external
        onlyPoolManager
    {
        PoolId id = key.toId();
        require(!pools[id].initialized, "FermiHook: pool already initialized");
        pools[id] = Pool({tokens: tokens, params: params, V: V, initialized: true});
        states[id] = Fermi3.createPool(params, V);
    }

    function coinIndex(Pool storage pool, address token) internal view returns (uint256) {
        if (token == pool.tokens[0]) return 0;
        if (token == pool.tokens[1]) return 1;
        if (token == pool.tokens[2]) return 2;
        revert UnknownToken();
    }

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata params, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId id = key.toId();
        Pool storage pool = pools[id];
        require(pool.initialized, "FermiHook: pool not initialized");

        uint256 i = coinIndex(pool, Currency.unwrap(key.currency0));
        uint256 j = coinIndex(pool, Currency.unwrap(key.currency1));

        Fermi3.State memory s = states[id];

        bool exactIn = params.amountSpecified < 0;
        uint256 amount = exactIn ? uint256(-params.amountSpecified) : uint256(params.amountSpecified);
        require(amount > 0, "FermiHook: zero amount");

        if (exactIn) {
            (, uint256[3] memory nx) = Fermi3.quoteExactIn(s, i, j, amount);
            s.x = nx;
            states[id] = s;
        } else {
            (, uint256[3] memory nx) = Fermi3.quoteExactOut(s, i, j, amount);
            s.x = nx;
            states[id] = s;
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _beforeAddLiquidity(address, PoolKey calldata key, ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        require(pools[key.toId()].initialized, "FermiHook: pool not initialized");
        return BaseHook.beforeAddLiquidity.selector;
    }

    function _beforeRemoveLiquidity(address, PoolKey calldata key, ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        require(pools[key.toId()].initialized, "FermiHook: pool not initialized");
        return BaseHook.beforeRemoveLiquidity.selector;
    }
}
