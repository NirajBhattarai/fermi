// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Fermi} from "../src/lib/Fermi.sol";

contract FermiTest is Test {
    uint256 internal constant WAD = 1e18;

    Fermi.Params internal params;
    Fermi.State internal pool;

    function setUp() public {
        uint256[] memory w = new uint256[](3);
        w[0] = 625e15;
        w[1] = 3125e14;
        w[2] = 625e14;

        uint256[] memory b = new uint256[](3);
        b[0] = 4e17;
        b[1] = 4e17;
        b[2] = 1e17;

        params = Fermi.Params({w: w, b: b, R: 10e18});
        pool = Fermi.createPool(params, 160e18);
    }

    /*//////////////////////////////////////////////////////////////
                             Y1 — PARAMETERS
    //////////////////////////////////////////////////////////////*/

    function test_Y1_PerCoinParameters() public pure {
        uint256[] memory w = new uint256[](3);
        w[0] = 625e15;
        w[1] = 3125e14;
        w[2] = 625e14;
        uint256[] memory b = new uint256[](3);
        b[0] = 4e17;
        b[1] = 4e17;
        b[2] = 1e17;
        Fermi.Params memory p = Fermi.Params({w: w, b: b, R: 10e18});

        uint256[3] memory expectedCap = [uint256(224e18), 224e18, 176e18];
        uint256[3] memory expectedTemp = [uint256(6400e15), 6400e15, 1600e15];
        uint256[3] memory expectedWall = [uint256(140e18), 70e18, 11e18];
        uint256[3] memory expectedRoom = [uint256(40e18), 20e18, 1e18];
        for (uint256 i; i < 3; i++) {
            assertApproxEqAbs(Fermi.cap(p, 160e18, i), expectedCap[i], 1e9, "cap");
            assertApproxEqAbs(Fermi.temp(p, 160e18, i), expectedTemp[i], 1e9, "temp");
            assertApproxEqAbs(Fermi.wall(p, 160e18, i), expectedWall[i], 1e9, "wall");
            assertApproxEqAbs(uint256(Fermi.room(Fermi.createPool(p, 160e18), i)), expectedRoom[i], 1e9, "room");
        }
    }

    function test_Y1_Constants() public view {
        assertApproxEqAbs(pool.K, -61000276933285228154, 1e6, "K direct");
        assertApproxEqAbs(Fermi.closedFormK(params, 160e18), -61000276933285228154, 1e6, "K closed form");
        assertApproxEqAbs(Fermi.phi(10e18), 999954602131297610, 1e6, "phi");
        assertApproxEqAbs(Fermi.epsilon0(params, 160e18), 276933285222874, 1e6, "eps0");
        assertApproxEqAbs(Fermi.lossBound(pool, 0), 140000276933285222874, 1e6, "USDC bound");
        assertApproxEqAbs(Fermi.lossBound(pool, 1), 70000276933285222874, 1e6, "USDT bound");
        assertApproxEqAbs(Fermi.lossBound(pool, 2), 11000276933285222874, 1e6, "NEW bound");
    }

    function test_Y2_BalancedFormIdentity() public view {
        uint256 penalty;
        for (uint256 i; i < 3; i++) {
            penalty += Fermi.epsilon(params, 160e18, i, pool.x[i]);
        }

        assertApproxEqAbs(pool.x[0] + pool.x[1] + pool.x[2] - penalty, 159999723066714778952, 1e7, "sum x - eps");
        assertApproxEqAbs(160e18 - Fermi.epsilon0(params, 160e18), 159999723066714778952, 1e7, "V - eps0");
    }

    /*//////////////////////////////////////////////////////////////
                             Y3 — SWAPS
    //////////////////////////////////////////////////////////////*/

    function test_Y3_ExactInAndRoundTrip() public view {
        (uint256 out, uint256[] memory next) = Fermi.quoteExactIn(pool, 0, 1, 5e18);
        assertApproxEqAbs(out, 4999631143542346842, 1e7, "5 USDC -> USDT");

        int256 drift = Fermi.invariant(params, 160e18, next) - pool.K;
        require(drift >= -1e12, "F must not fall below K");
        if (drift > 0) assertApproxEqAbs(uint256(drift), 0, 1e13, "post-swap drift");

        Fermi.State memory afterIn = Fermi.State({params: params, x: next, V: 160e18, K: pool.K});
        (uint256 back,) = Fermi.quoteExactOut(afterIn, 1, 0, 5e18);
        assertApproxEqAbs(back, out, 1e10, "round trip input");
    }

    function test_Y3_ExactOut() public view {
        (uint256 needed,) = Fermi.quoteExactOut(pool, 0, 1, 5e18);
        assertApproxEqAbs(needed, 5000368913534869000, 1e7, "USDC for 5 USDT");
    }

    function test_Y3_Capacities() public view {
        (uint256 cap01, bool drain01) = Fermi.capacity(pool, 0, 1);
        (uint256 cap10, bool drain10) = Fermi.capacity(pool, 1, 0);
        (uint256 cap20, bool drain20) = Fermi.capacity(pool, 2, 0);
        assertApproxEqAbs(cap01, 40000272393295128745, 1e7, "cap USDC->USDT");
        assertApproxEqAbs(cap10, 20000271169769165533, 1e7, "cap USDT->USDC");
        assertApproxEqAbs(cap20, 1000044709464377854, 1e7, "cap NEW->USDC");
        require(!drain01 && !drain10 && !drain20, "should not be drainable");
    }

    function externalExactOut(Fermi.State memory s, uint256 i, uint256 j, uint256 amount) external pure {
        Fermi.quoteExactOut(s, i, j, amount);
    }

    function externalExactIn(Fermi.State memory s, uint256 i, uint256 j, uint256 amount) external pure {
        Fermi.quoteExactIn(s, i, j, amount);
    }

    function test_Y3_RevertWhenExactOutExceedsCapacity() public {
        vm.expectRevert(Fermi.CapacityExceeded.selector);
        this.externalExactOut(pool, 2, 0, 15e17);
    }

    /*//////////////////////////////////////////////////////////////
                       Y4/Y5 — HOMOGENEITY AND DEPOSIT
    //////////////////////////////////////////////////////////////*/

    function test_Y4_Homogeneity() public pure {
        uint256[] memory w = new uint256[](3);
        w[0] = 625e15;
        w[1] = 3125e14;
        w[2] = 625e14;
        uint256[] memory b = new uint256[](3);
        b[0] = 4e17;
        b[1] = 4e17;
        b[2] = 1e17;
        Fermi.Params memory p = Fermi.Params({w: w, b: b, R: 10e18});
        Fermi.State memory base = Fermi.createPool(p, 160e18);

        uint256[3] memory lambdas = [uint256(2e18), 10e18, 1e15];
        int256[3] memory expectedK = [int256(-122000553866570456308), -610002769332852281540, -61000276933285228];
        for (uint256 t; t < 3; t++) {
            uint256 lam = lambdas[t];
            uint256 V = (160e18 * lam) / WAD;
            uint256[] memory scaled = new uint256[](3);
            for (uint256 i; i < 3; i++) {
                scaled[i] = (base.x[i] * lam) / WAD;
            }

            int256 K = Fermi.invariant(p, V, scaled);
            assertApproxEqAbs(K, (base.K * int256(lam)) / int256(WAD), 1e7, "homogeneous K");
            assertApproxEqAbs(K, expectedK[t], 1e7, "expected K");

            Fermi.State memory q = Fermi.State({params: p, x: scaled, V: V, K: K});
            assertApproxEqAbs(Fermi.spot(q, 0, 1), WAD, 1e9, "spot at balance");
        }
    }

    function test_Y5_SpotUnchangedByProportionalAdd() public view {
        (, uint256[] memory next) = Fermi.quoteExactIn(pool, 0, 1, 5e18);
        Fermi.State memory before = Fermi.State({params: params, x: next, V: 160e18, K: pool.K});

        uint256 spot01 = Fermi.spot(before, 0, 1);
        uint256 spot20 = Fermi.spot(before, 2, 0);

        uint256[] memory scaled = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            scaled[i] = (next[i] * 125) / 100;
        }
        Fermi.State memory afterAdd =
            Fermi.State({params: params, x: scaled, V: (160e18 * 125) / 100, K: (pool.K * 125) / 100});

        assertApproxEqAbs(Fermi.invariant(params, afterAdd.V, scaled), afterAdd.K, 1e12, "F scales with V");
        assertApproxEqAbs(Fermi.spot(afterAdd, 0, 1), spot01, 1e9, "spot 01 unchanged");
        assertApproxEqAbs(Fermi.spot(afterAdd, 2, 0), spot20, 1e9, "spot 20 unchanged");
    }

    /*//////////////////////////////////////////////////////////////
                             Y7 — NO DRAIN
    //////////////////////////////////////////////////////////////*/

    function test_Y7_NoDrainFlags() public view {
        (, bool usdcOk) = Fermi.noDrain(params, 160e18, 0);
        (, bool usdtOk) = Fermi.noDrain(params, 160e18, 1);
        (int256 newMargin, bool newOk) = Fermi.noDrain(params, 160e18, 2);
        require(usdcOk && usdtOk, "USDC/USDT guaranteed");
        require(!newOk, "NEW not guaranteed");
        assertApproxEqAbs(newMargin, -3125e14, 1e9, "NEW margin");
    }

    /*//////////////////////////////////////////////////////////////
                               FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ExpNegIsBoundedAndMonotone(uint256 aRaw) public pure {
        uint256 a = bound(aRaw, 0, 42e18);
        uint256 e = Fermi.expNegWad(a);
        require(e <= WAD, "exp(-a) <= 1");
        if (a < 42e18) require(Fermi.expNegWad(a + 1) <= e, "monotone decreasing");
    }

    function testFuzz_SoftplusInverseRoundTrip(uint256 zRaw) public pure {
        uint256 z = bound(zRaw, 1e12, 30e18);
        uint256 back = uint256(Fermi.softplusInv(uint256(Fermi.softplus(int256(z)))));
        assertApproxEqAbs(back, z, 1e11, "softplus round trip");
    }

    function testFuzz_ExactInPreservesInvariant(uint256 seed) public view {
        uint256 i = seed % 3;
        uint256 j = (i + 1 + (seed / 3) % 2) % 3;
        (uint256 available, bool drainable) = Fermi.capacity(pool, i, j);
        if (drainable || available <= 2e15) return;
        uint256 amount = bound(seed / 8, 1e15, available / 2);
        (, uint256[] memory next) = Fermi.quoteExactIn(pool, i, j, amount);
        assertInvariantDrift(next);
    }

    function testFuzz_ExactOutPreservesInvariant(uint256 seed) public view {
        uint256 amount = bound(seed, 1e15, 1e18);
        (, uint256[] memory next) = Fermi.quoteExactOut(pool, 0, 1, amount);
        assertInvariantDrift(next);
    }

    function assertInvariantDrift(uint256[] memory x) internal view {
        int256 drift = Fermi.invariant(params, pool.V, x) - pool.K;
        require(drift >= -1e12, "F must not fall below K");
        if (drift > 0) assertApproxEqAbs(uint256(drift), 0, 1e13, "F drift bounded");
    }

    function testFuzz_RoundTripOverAmounts(uint256 seed) public view {
        (uint256 available, bool drainable) = Fermi.capacity(pool, 0, 1);
        if (drainable) return;
        uint256 amount = bound(seed, 1e15, available / 2);
        (uint256 out, uint256[] memory next) = Fermi.quoteExactIn(pool, 0, 1, amount);
        Fermi.State memory afterIn = Fermi.State({params: params, x: next, V: pool.V, K: pool.K});
        (uint256 back,) = Fermi.quoteExactOut(afterIn, 1, 0, amount);
        uint256 err = back > out ? back - out : out - back;
        require(err <= 1e10, "round trip error");
    }

    function testFuzz_SpotAtBalanceIsOne(uint256 vRaw, uint256 bRaw, uint256 rRaw) public pure {
        uint256 V = bound(vRaw, 1e18, 1e24);
        uint256 b = bound(bRaw, 1e16, 1e18);
        uint256 R = bound(rRaw, 8e18, 100e18);
        uint256[] memory w = new uint256[](2);
        w[0] = 4e17;
        w[1] = 6e17;
        uint256[] memory bs = new uint256[](2);
        bs[0] = b;
        bs[1] = b;
        Fermi.State memory balanced = Fermi.createPool(Fermi.Params({w: w, b: bs, R: R}), V);
        uint256 price = Fermi.spot(balanced, 0, 1);
        uint256 diff = price > WAD ? price - WAD : WAD - price;
        require(diff <= 1e9, "balanced spot within 1e-9 of par");
    }

    function testFuzz_LossFloorAfterRandomSwaps(uint256 seed) public view {
        uint256 x = seed == 0 ? 1 : seed;
        Fermi.State memory s = pool;
        for (uint256 step; step < 8; step++) {
            unchecked {
                x = (x * 1103515245 + 12345) % 1000000007;
            }
            (uint256 available, bool drainable) = Fermi.capacity(s, 0, 1);
            if (drainable || available <= 2e17) break;
            uint256 amount = 1e15 + (x % (available / 2));
            (, uint256[] memory next) = Fermi.quoteExactIn(s, 0, 1, amount);
            s.x = next;

            assertInvariantDrift(s.x);

            int256 C = s.K + int256(Fermi.wall(params, s.V, 0)) + int256(Fermi.wall(params, s.V, 1))
                + int256(Fermi.wall(params, s.V, 2));
            for (uint256 h; h < 3; h++) {
                uint256 good;
                for (uint256 k; k < 3; k++) {
                    if (k != h) good += s.x[k];
                }
                require(int256(good) >= C - int256(Fermi.wall(params, s.V, h)) - 1e13, "T4 margin");
            }
        }
    }

    function testFuzz_RevertWhenSameCoin(uint256 seed) public {
        uint256 amount = bound(seed, 1, 1e18);
        vm.expectRevert(Fermi.InvalidInput.selector);
        this.externalExactIn(pool, 1, 1, amount);
    }
}
