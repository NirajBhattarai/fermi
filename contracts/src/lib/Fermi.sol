// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FixedPointMathLib as FPM} from "solmate/src/utils/FixedPointMathLib.sol";

/// @title Fermi
/// @notice Balanced Fermi–Dirac invariant math for multi-stablecoin baskets,
///         following docs/yellow-paper.md. All quantities are 18-decimal fixed
///         point; curve contributions (f, term, K) are signed.
/// @dev Every exponential is evaluated on a non-positive argument (§8.2). The
///      library is pure math: it holds no state and moves no tokens.
library Fermi {
    uint256 internal constant WAD = 1e18;
    /// @dev x_min from §8.4: 1e-12 in wad units.
    uint256 internal constant X_MIN = 1e6;
    /// @dev Conservative quote offset covering ln/exp truncation (§8.3).
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
        uint256[] w;
        uint256[] b;
        uint256 R;
    }

    struct State {
        Params params;
        uint256[] x;
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

    /// @dev ln(x) for x > 0, wad in / signed wad out. Range reduction by
    ///      powers of two, then the atanh series ln(m) = 2 Σ y^(2k+1)/(2k+1).
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

    /// @dev exp(-a) for a >= 0. Range reduction by 2^8 followed by the Taylor
    ///      series, then eight squarings. Returns 0 below half a wei.
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

    /// @dev σ(z) = ln(1 + e^z), stable for either sign of z.
    function softplus(int256 z) internal pure returns (uint256) {
        uint256 magnitude = z < 0 ? uint256(-z) : uint256(z);
        uint256 logTerm = uint256(lnWad(WAD + expNegWad(magnitude)));
        return (z > 0 ? uint256(z) : 0) + logTerm;
    }

    /// @dev σ⁻¹(a) = a + ln(1 - e^-a), signed because it is negative for a < 1.
    ///      Small-a branch uses the convergent expansion
    ///      a/2 + ln(a) + a²/24 - a⁴/2880 to avoid cancellation.
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

    /// @dev f_i(r) = -T_i σ((c_i - r)/T_i) <= 0.
    function f(Params memory p, uint256 V, uint256 i, uint256 r) internal pure returns (int256) {
        int256 z = divWadSigned(int256(cap(p, V, i)) - int256(r), temp(p, V, i));
        return -mulWadSigned(int256(softplus(z)), temp(p, V, i));
    }

    /// @dev f_i'(r) = 1 / (1 + e^((r-c)/T)) in (0, 1).
    function fPrime(Params memory p, uint256 V, uint256 i, uint256 r) internal pure returns (uint256) {
        int256 z = divWadSigned(int256(r) - int256(cap(p, V, i)), temp(p, V, i));
        if (z > 0) {
            uint256 ey = expNegWad(uint256(z));
            return FPM.divWadDown(ey, WAD + ey);
        }
        uint256 ez = expNegWad(uint256(-z));
        return FPM.divWadDown(WAD, WAD + ez);
    }

    /// @dev g_i(u) = f_i⁻¹(u) = c_i - T_i σ⁻¹(-u/T_i) for u < 0.
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

    /// @dev ε_i(x_i) = w_i T_i σ((r_i - c_i)/T_i) >= 0 (§3.5).
    function epsilon(Params memory p, uint256 V, uint256 i, uint256 xi) internal pure returns (uint256) {
        uint256 r = FPM.divWadDown(xi, p.w[i]);
        int256 z = divWadSigned(int256(r) - int256(cap(p, V, i)), temp(p, V, i));
        return FPM.mulWadDown(FPM.mulWadDown(p.w[i], temp(p, V, i)), softplus(z));
    }

    /*//////////////////////////////////////////////////////////////
                            INVARIANT (§3)
    //////////////////////////////////////////////////////////////*/

    function validate(Params memory p, uint256 V) internal pure {
        uint256 n = p.w.length;
        if (n < 2 || p.b.length != n || V == 0) revert InvalidParams();
        if (p.R < MIN_R || p.R > MAX_R) revert InvalidParams();

        uint256 weightSum;
        for (uint256 i; i < n; i++) {
            if (p.w[i] == 0 || p.b[i] == 0) revert InvalidParams();
            weightSum += p.w[i];
        }
        if (weightSum < WAD - n || weightSum > WAD + n) revert InvalidParams();
    }

    function invariant(Params memory p, uint256 V, uint256[] memory x) internal pure returns (int256) {
        if (x.length != p.w.length) revert InvalidParams();
        int256 result;
        for (uint256 i; i < x.length; i++) {
            result += term(p, V, i, x[i]);
        }
        return result;
    }

    function weightedBudget(Params memory p) internal pure returns (uint256 result) {
        for (uint256 i; i < p.w.length; i++) {
            result += FPM.mulWadDown(p.w[i], p.b[i]);
        }
    }

    /// @dev K = -σ(R)/R · V · Σ w_i b_i (§3.3).
    function closedFormK(Params memory p, uint256 V) internal pure returns (int256) {
        uint256 ratio = FPM.divWadDown(softplus(int256(p.R)), p.R);
        uint256 product = FPM.mulWadDown(FPM.mulWadDown(ratio, V), weightedBudget(p));
        return -int256(product);
    }

    /// @dev ε₀ = σ(-R)/R · V · Σ w_i b_i (§3.5).
    function epsilon0(Params memory p, uint256 V) internal pure returns (uint256) {
        uint256 ratio = FPM.divWadDown(softplus(-int256(p.R)), p.R);
        return FPM.mulWadDown(FPM.mulWadDown(ratio, V), weightedBudget(p));
    }

    /// @dev φ = 1/(1 + e^-R), the common slope at the balanced state (T1).
    function phi(uint256 R) internal pure returns (uint256) {
        return FPM.divWadDown(WAD, WAD + expNegWad(R));
    }

    function createPool(Params memory p, uint256 V) internal pure returns (State memory s) {
        validate(p, V);
        s.params = p;
        s.V = V;
        s.x = new uint256[](p.w.length);
        for (uint256 i; i < p.w.length; i++) {
            s.x[i] = FPM.mulWadDown(p.w[i], V);
        }
        s.K = invariant(p, V, s.x);
    }

    /// @dev p_{i→j} = f_i'(r_i) / f_j'(r_j) (T1).
    function spot(State memory s, uint256 i, uint256 j) internal pure returns (uint256) {
        if (i == j || i >= s.x.length || j >= s.x.length) revert InvalidInput();
        uint256 numerator = fPrime(s.params, s.V, i, FPM.divWadDown(s.x[i], s.params.w[i]));
        uint256 denominator = fPrime(s.params, s.V, j, FPM.divWadDown(s.x[j], s.params.w[j]));
        return FPM.divWadDown(numerator, denominator);
    }

    function restTerms(State memory s, uint256 skipA, uint256 skipB) internal pure returns (int256 result) {
        for (uint256 k; k < s.x.length; k++) {
            if (k != skipA && k != skipB) result += term(s.params, s.V, k, s.x[k]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            SWAPS (§6.1, §6.2)
    //////////////////////////////////////////////////////////////*/

    function checkPair(State memory s, uint256 i, uint256 j) internal pure {
        if (i == j || i >= s.x.length || j >= s.x.length) revert InvalidInput();
    }

    /// @dev Exact input: returns the output of j and the post-swap reserves.
    function quoteExactIn(State memory s, uint256 i, uint256 j, uint256 amountIn)
        internal
        pure
        returns (uint256 amountOut, uint256[] memory nextX)
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

        nextX = new uint256[](s.x.length);
        for (uint256 k; k < s.x.length; k++) {
            nextX[k] = s.x[k];
        }
        nextX[i] = xi2;
        nextX[j] = uint256(xj2);
    }

    /// @dev Exact output: returns the input of i needed and the post-swap reserves.
    function quoteExactOut(State memory s, uint256 i, uint256 j, uint256 amountOut)
        internal
        pure
        returns (uint256 amountIn, uint256[] memory nextX)
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
        nextX = new uint256[](s.x.length);
        for (uint256 k; k < s.x.length; k++) {
            nextX[k] = s.x[k];
        }
        nextX[i] = uint256(xi2);
        nextX[j] = xj2;
    }

    /*//////////////////////////////////////////////////////////////
                       CAPACITY AND BOUNDS (§T4–T6)
    //////////////////////////////////////////////////////////////*/

    /// @dev T5: supremum of output over all input sizes, capped by x_j.
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

    /// @dev Room in coin i before its wall; negative once past it.
    function room(State memory s, uint256 i) internal pure returns (int256) {
        return int256(wall(s.params, s.V, i)) - int256(s.x[i]);
    }

    /// @dev T4 single failure: LP loss <= w_h c_h + ε₀.
    function lossBound(State memory s, uint256 h) internal pure returns (uint256) {
        return wall(s.params, s.V, h) + epsilon0(s.params, s.V);
    }

    /// @dev T6: margin = w_j - Σ_{k≠j} w_k b_k; guaranteed when margin > ε₀/V.
    function noDrain(Params memory p, uint256 V, uint256 j) internal pure returns (int256 margin, bool ok) {
        int256 others;
        for (uint256 k; k < p.w.length; k++) {
            if (k != j) others += int256(FPM.mulWadDown(p.w[k], p.b[k]));
        }
        margin = int256(p.w[j]) - others;
        ok = margin > int256(FPM.divWadDown(epsilon0(p, V), V));
    }
}
