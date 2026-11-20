// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FixedPointMathLib as FPM} from "solmate/src/utils/FixedPointMathLib.sol";

/// @title Fermi3
/// @notice 3-coin specialization of the Fermi balanced invariant (§ docs/yellow-paper.md).
///         Identical math to `Fermi`, but fixed-size `uint256[3]` structs: no dynamic
///         memory allocations, unrolled loops, and direct per-coin indexing.
/// @dev Pure math library: holds no state and moves no tokens.
library Fermi3 {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant X_MIN = 1e6;
    uint256 internal constant QUOTE_SLACK = 1e8;
    uint256 internal constant LN2_WAD = 693147180559945309;
    uint256 internal constant MIN_R = 8e18;
    uint256 internal constant MAX_R = 1000e18;

    error InvalidParams();
    error InvalidInput();
    error Drain();
    error ZeroOutput();
    error CapacityExceeded();
    error MathDomain();

    struct Params {
        uint256[3] w;
        uint256[3] b;
        uint256 R;
    }

    struct State {
        Params params;
        uint256[3] x;
        uint256 V;
        int256 K;
    }

    /*//////////////////////////////////////////////////////////////
                          SIGNED FIXED POINT
    //////////////////////////////////////////////////////////////*/

    function mulWadSigned(int256 a, uint256 b) internal pure returns (int256) {
        if (a >= 0) return int256(FPM.mulWadDown(uint256(a), b));
        return -int256(FPM.mulWadDown(uint256(-a), b));
    }

    function divWadSigned(int256 a, uint256 b) internal pure returns (int256) {
        if (b == 0) revert MathDomain();
        if (a >= 0) return int256(FPM.divWadDown(uint256(a), b));
        return -int256(FPM.divWadDown(uint256(-a), b));
    }

    function mulSigned(int256 a, int256 b) internal pure returns (int256) {
        bool negative = (a < 0) != (b < 0);
        uint256 magnitudeA = a < 0 ? uint256(-a) : uint256(a);
        uint256 magnitudeB = b < 0 ? uint256(-b) : uint256(b);
        int256 result = int256(FPM.mulWadDown(magnitudeA, magnitudeB));
        return negative ? -result : result;
    }

    /*//////////////////////////////////////////////////////////////
                              PRIMITIVES (§8.2)
    //////////////////////////////////////////////////////////////*/

    function lnWad(uint256 x) internal pure returns (int256) {
        if (x == 0) revert MathDomain();

        int256 exponent;
        while (x >= 2 * WAD) {
            x = (x >> 1) + (x & 1);
            exponent++;
        }
        while (x < WAD) {
            x <<= 1;
            exponent--;
        }

        uint256 y = FPM.divWadDown(x - WAD, x + WAD);
        uint256 y2 = FPM.mulWadDown(y, y);
        uint256 power = y;
        uint256 sum = y;
        for (uint256 k = 1; k <= 24; k++) {
            power = FPM.mulWadDown(power, y2);
            if (power == 0) break;
            sum += power / (2 * k + 1);
        }

        return int256(2 * sum) + exponent * int256(LN2_WAD);
    }

    function expNegWad(uint256 a) internal pure returns (uint256) {
        if (a == 0) return WAD;
        if (a > 42 * WAD) return 0;

        uint256 t = a >> 8;
        uint256 power = WAD;
        int256 sum = int256(WAD);
        for (uint256 k = 1; k <= 18; k++) {
            power = FPM.mulWadDown(power, t) / k;
            if (power == 0) break;
            if (k & 1 == 1) sum -= int256(power);
            else sum += int256(power);
        }
        if (sum < 0) return 0;

        uint256 result = uint256(sum);
        for (uint256 i = 0; i < 8; i++) {
            result = FPM.mulWadDown(result, result);
        }
        return result;
    }

    function softplus(int256 z) internal pure returns (uint256) {
        uint256 magnitude = z < 0 ? uint256(-z) : uint256(z);
        uint256 logTerm = uint256(lnWad(WAD + expNegWad(magnitude)));
        return (z > 0 ? uint256(z) : 0) + logTerm;
    }

    function softplusInv(uint256 a) internal pure returns (int256) {
        if (a == 0) revert MathDomain();
        if (a >= 40 * WAD) return int256(a);

        if (a <= 1e16) {
            uint256 a2 = FPM.mulWadDown(a, a);
            int256 result = int256(a / 2) + lnWad(a);
            result += int256(a2 / 24);
            result -= int256(FPM.mulWadDown(a2, a2) / 2880);
            return result;
        }

        uint256 oneMinus = WAD - expNegWad(a);
        if (oneMinus == 0) return int256(a);
        return int256(a) + lnWad(oneMinus);
    }

    /*//////////////////////////////////////////////////////////////
                         PER-COIN PARAMETERS (§1)
    //////////////////////////////////////////////////////////////*/

    function cap(Params memory p, uint256 V, uint256 i) internal pure returns (uint256) {
        return FPM.mulWadDown(V, WAD + p.b[i]);
    }

    function temp(Params memory p, uint256 V, uint256 i) internal pure returns (uint256) {
        return FPM.divWadDown(FPM.mulWadDown(V, p.b[i]), p.R);
    }

    function wall(Params memory p, uint256 V, uint256 i) internal pure returns (uint256) {
        return FPM.mulWadDown(p.w[i], cap(p, V, i));
    }

    function f(Params memory p, uint256 V, uint256 i, uint256 r) internal pure returns (int256) {
        int256 z = divWadSigned(int256(cap(p, V, i)) - int256(r), temp(p, V, i));
        return -mulWadSigned(int256(softplus(z)), temp(p, V, i));
    }

    function fPrime(Params memory p, uint256 V, uint256 i, uint256 r) internal pure returns (uint256) {
        int256 z = divWadSigned(int256(r) - int256(cap(p, V, i)), temp(p, V, i));
        if (z > 0) {
            uint256 ey = expNegWad(uint256(z));
            return FPM.divWadDown(ey, WAD + ey);
        }
        uint256 ez = expNegWad(uint256(-z));
        return FPM.divWadDown(WAD, WAD + ez);
    }

    function g(Params memory p, uint256 V, uint256 i, int256 u) internal pure returns (int256) {
        if (u >= 0) revert CapacityExceeded();
        uint256 T = temp(p, V, i);
        uint256 a = uint256(-divWadSigned(u, T));
        return int256(cap(p, V, i)) - mulWadSigned(softplusInv(a), T);
    }

    function term(Params memory p, uint256 V, uint256 i, uint256 xi) internal pure returns (int256) {
        uint256 r = FPM.divWadDown(xi, p.w[i]);
        return mulSigned(int256(p.w[i]), f(p, V, i, r));
    }

    function epsilon(Params memory p, uint256 V, uint256 i, uint256 xi) internal pure returns (uint256) {
        uint256 r = FPM.divWadDown(xi, p.w[i]);
        int256 z = divWadSigned(int256(r) - int256(cap(p, V, i)), temp(p, V, i));
        return FPM.mulWadDown(FPM.mulWadDown(p.w[i], temp(p, V, i)), softplus(z));
    }

    /*//////////////////////////////////////////////////////////////
                            INVARIANT (§3)
    //////////////////////////////////////////////////////////////*/

    function validate(Params memory p, uint256 V) internal pure {
        if (V == 0) revert InvalidParams();
        if (p.R < MIN_R || p.R > MAX_R) revert InvalidParams();

        uint256 weightSum;
        for (uint256 i; i < 3; i++) {
            if (p.w[i] == 0 || p.b[i] == 0) revert InvalidParams();
            weightSum += p.w[i];
        }
        if (weightSum < WAD - 3 || weightSum > WAD + 3) revert InvalidParams();
    }

    function invariant(Params memory p, uint256 V, uint256[3] memory x) internal pure returns (int256) {
        return term(p, V, 0, x[0]) + term(p, V, 1, x[1]) + term(p, V, 2, x[2]);
    }

    function weightedBudget(Params memory p) internal pure returns (uint256 result) {
        result = FPM.mulWadDown(p.w[0], p.b[0]);
        result += FPM.mulWadDown(p.w[1], p.b[1]);
        result += FPM.mulWadDown(p.w[2], p.b[2]);
    }

    function closedFormK(Params memory p, uint256 V) internal pure returns (int256) {
        uint256 ratio = FPM.divWadDown(softplus(int256(p.R)), p.R);
        uint256 product = FPM.mulWadDown(FPM.mulWadDown(ratio, V), weightedBudget(p));
        return -int256(product);
    }

    function epsilon0(Params memory p, uint256 V) internal pure returns (uint256) {
        uint256 ratio = FPM.divWadDown(softplus(-int256(p.R)), p.R);
        return FPM.mulWadDown(FPM.mulWadDown(ratio, V), weightedBudget(p));
    }

    function phi(uint256 R) internal pure returns (uint256) {
        return FPM.divWadDown(WAD, WAD + expNegWad(R));
    }

    function createPool(Params memory p, uint256 V) internal pure returns (State memory s) {
        validate(p, V);
        s.params = p;
        s.V = V;
        s.x[0] = FPM.mulWadDown(p.w[0], V);
        s.x[1] = FPM.mulWadDown(p.w[1], V);
        s.x[2] = FPM.mulWadDown(p.w[2], V);
        s.K = invariant(p, V, s.x);
    }

    function spot(State memory s, uint256 i, uint256 j) internal pure returns (uint256) {
        if (i == j || i > 2 || j > 2) revert InvalidInput();
        uint256 numerator = fPrime(s.params, s.V, i, FPM.divWadDown(s.x[i], s.params.w[i]));
        uint256 denominator = fPrime(s.params, s.V, j, FPM.divWadDown(s.x[j], s.params.w[j]));
        return FPM.divWadDown(numerator, denominator);
    }

    function restTerms(State memory s, uint256 i, uint256 j) internal pure returns (int256) {
        uint256 k = 3 - i - j;
        return term(s.params, s.V, k, s.x[k]);
    }

    /*//////////////////////////////////////////////////////////////
                            SWAPS (§6.1, §6.2)
    //////////////////////////////////////////////////////////////*/

    function checkPair(State memory s, uint256 i, uint256 j) internal pure {
        if (i == j || i > 2 || j > 2) revert InvalidInput();
    }

    function quoteExactIn(State memory s, uint256 i, uint256 j, uint256 amountIn)
        internal
        pure
        returns (uint256 amountOut, uint256[3] memory nextX)
    {
        checkPair(s, i, j);
        if (amountIn == 0) revert InvalidInput();

        uint256 xi2 = s.x[i] + amountIn;
        int256 u = divWadSigned(s.K - restTerms(s, i, j) - term(s.params, s.V, i, xi2), s.params.w[j]);
        if (u >= 0) revert CapacityExceeded();

        int256 gj = g(s.params, s.V, j, u);
        if (gj <= 0) revert Drain();
        int256 xj2 = mulWadSigned(int256(s.params.w[j]), uint256(gj));
        if (xj2 <= int256(X_MIN)) revert Drain();
        if (uint256(xj2) >= s.x[j]) revert ZeroOutput();

        amountOut = s.x[j] - uint256(xj2);
        if (amountOut <= QUOTE_SLACK) revert ZeroOutput();
        amountOut -= QUOTE_SLACK;

        nextX[0] = s.x[0];
        nextX[1] = s.x[1];
        nextX[2] = s.x[2];
        nextX[i] = xi2;
        nextX[j] = uint256(xj2);
    }

    function quoteExactOut(State memory s, uint256 i, uint256 j, uint256 amountOut)
        internal
        pure
        returns (uint256 amountIn, uint256[3] memory nextX)
    {
        checkPair(s, i, j);
        if (amountOut == 0 || amountOut >= s.x[j]) revert InvalidInput();

        uint256 xj2 = s.x[j] - amountOut;
        if (xj2 <= X_MIN) revert Drain();

        int256 u = divWadSigned(s.K - restTerms(s, i, j) - term(s.params, s.V, j, xj2), s.params.w[i]);
        if (u >= 0) revert CapacityExceeded();

        int256 gi = g(s.params, s.V, i, u);
        if (gi <= 0) revert Drain();
        int256 xi2 = mulWadSigned(int256(s.params.w[i]), uint256(gi));
        if (xi2 <= int256(s.x[i])) revert ZeroOutput();

        amountIn = uint256(xi2 - int256(s.x[i])) + QUOTE_SLACK;
        nextX[0] = s.x[0];
        nextX[1] = s.x[1];
        nextX[2] = s.x[2];
        nextX[i] = uint256(xi2);
        nextX[j] = xj2;
    }

    /*//////////////////////////////////////////////////////////////
                       CAPACITY AND BOUNDS (§T4–T6)
    //////////////////////////////////////////////////////////////*/

    function capacity(State memory s, uint256 i, uint256 j) internal pure returns (uint256 amount, bool drainable) {
        checkPair(s, i, j);
        int256 u = divWadSigned(s.K - restTerms(s, i, j), s.params.w[j]);
        if (u >= 0) return (s.x[j], true);

        int256 gj = g(s.params, s.V, j, u);
        if (gj <= 0) return (s.x[j], true);
        int256 raw = int256(s.x[j]) - mulWadSigned(int256(s.params.w[j]), uint256(gj));
        if (raw >= int256(s.x[j])) return (s.x[j], true);
        if (raw <= int256(QUOTE_SLACK)) return (0, false);
        return (uint256(raw) - QUOTE_SLACK, false);
    }

    function room(State memory s, uint256 i) internal pure returns (int256) {
        return int256(wall(s.params, s.V, i)) - int256(s.x[i]);
    }

    function lossBound(State memory s, uint256 h) internal pure returns (uint256) {
        return wall(s.params, s.V, h) + epsilon0(s.params, s.V);
    }

    function noDrain(Params memory p, uint256 V, uint256 j) internal pure returns (int256 margin, bool ok) {
        int256 others;
        for (uint256 k; k < 3; k++) {
            if (k != j) others += int256(FPM.mulWadDown(p.w[k], p.b[k]));
        }
        margin = int256(p.w[j]) - others;
        ok = margin > int256(FPM.divWadDown(epsilon0(p, V), V));
    }
}
