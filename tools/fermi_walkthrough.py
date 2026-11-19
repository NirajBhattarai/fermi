"""Every number in docs/fermi-from-scratch.md.

One running example, start to finish: a weighted Fermi pool holding
USDC 100M / USDT 50M / NEW 10M, popular coins on a 40% budget, NEW on 10%.
Curve numbers use the exact 3pool contract maths from curve_vs_fermi_sim.py.
All swaps are fee-free so the invariant can be checked exactly. Units are $M.

    python3 tools/fermi_walkthrough.py
"""

import math

from curve_vs_fermi_sim import A_LIVE, attack, curve_out, curve_spot

COINS = ("USDC", "USDT", "NEW")
X0 = [100.0, 50.0, 10.0]
V = sum(X0)
W = [x / V for x in X0]
BUDGETS = [0.40, 0.40, 0.10]
R_DEFAULT = 10.0


class WeightedFermi:
    """sum_i w_i f_i(x_i / w_i) = K,  f_i(r) = -T_i ln(1 + e^((c_i - r)/T_i))."""

    def __init__(self, budgets=BUDGETS, ratio=R_DEFAULT, ratios=None, x0=X0):
        ratios = ratios or [ratio] * len(budgets)
        self.c = [V * (1 + b) for b in budgets]
        self.T = [(c - V) / r for c, r in zip(self.c, ratios)]
        self.K = self.F(x0)

    def f(self, k, r):
        u = (self.c[k] - r) / self.T[k]
        return -self.T[k] * (max(u, 0.0) + math.log1p(math.exp(-abs(u))))

    def fp(self, k, r):
        z = (r - self.c[k]) / self.T[k]
        return math.exp(-z) / (1 + math.exp(-z)) if z > 0 else 1 / (1 + math.exp(z))

    def g(self, k, u):
        if u >= 0:
            return math.inf
        a = -u / self.T[k]
        return self.c[k] - self.T[k] * (a + math.log(-math.expm1(-a)))

    def term(self, k, x):
        return W[k] * self.f(k, x / W[k])

    def F(self, xp):
        return sum(self.term(k, x) for k, x in enumerate(xp))

    def spot(self, xp, i, j):
        return self.fp(i, xp[i] / W[i]) / self.fp(j, xp[j] / W[j])

    def solve(self, xp, i, j, dx):
        """Return every intermediate of a swap so the doc can show the steps."""
        rest = sum(self.term(k, xp[k]) for k in range(len(xp)) if k not in (i, j))
        ti = self.term(i, xp[i] + dx)
        need = (self.K - rest - ti) / W[j]
        rj = self.g(j, need)
        return rest, ti, need, rj, W[j] * rj

    def out(self, xp, i, j, dx, fee=0.0):
        xj_new = self.solve(xp, i, j, dx)[4]
        return max(xp[j] - xj_new, 0.0) * (1 - fee)


def curve_fn(xp, i, j, dx, fee):
    return curve_out(xp, i, j, dx, A_LIVE, fee)


def bps(out, dx):
    return (1 - out / dx) * 1e4


def section(title):
    print(f"\n[{title}]")


def main():
    P = WeightedFermi()

    section("1 parameters")
    print(f"  V = {V:.0f}   R = (c_i - V)/T_i = {R_DEFAULT:.0f}")
    for k, name in enumerate(COINS):
        print(f"  {name:5s} x={X0[k]:6.1f} w={W[k]:.4f} b={BUDGETS[k]:.0%} "
              f"c={P.c[k]:6.1f} T={P.T[k]:5.2f} wall w*c={W[k] * P.c[k]:6.2f} "
              f"room={W[k] * P.c[k] - X0[k]:6.2f} loss cap={W[k] * P.c[k] / V:6.2%}")

    section("2 target state")
    for k, name in enumerate(COINS):
        r = X0[k] / W[k]
        print(f"  {name:5s} r={r:.1f}  w*f(r)={P.term(k, X0[k]):.8f}  f'(r)={P.fp(k, r):.10f}")
    print(f"  K = {P.K:.8f}")
    print(f"  hand check: f'(V) = 1/(1+e^-10) = {1 / (1 + math.exp(-10)):.10f}")
    print(f"  near-peg approx K ~ sum x - sum w c = {V - sum(W[k] * P.c[k] for k in range(3)):.8f}")
    for i in range(3):
        for j in range(3):
            if i != j:
                print(f"  p({COINS[i]}->{COINS[j]}) = {P.spot(X0, i, j):.10f}")

    section("3 without the outer w_i")
    for i, j in ((2, 0), (0, 1)):
        p = (P.fp(i, V) / W[i]) / (P.fp(j, V) / W[j])
        print(f"  p({COINS[i]}->{COINS[j]}) = {p:.4f}")

    section("4 swap step by step")
    for i, j, dx in ((0, 1, 5.0), (2, 0, 1.0), (2, 0, 5.0)):
        rest, ti, need, rj, xj = P.solve(X0, i, j, dx)
        xp = list(X0)
        xp[i] += dx
        xp[j] = xj
        out = X0[j] - xj
        print(f"  {COINS[i]}->{COINS[j]} dx={dx}: x_i'={X0[i] + dx:.4f} r_i'={(X0[i] + dx) / W[i]:.4f} "
              f"term_i'={ti:.8f} rest={rest:.8f} need={need:.8f} r_j'={rj:.6f} "
              f"x_j'={xj:.6f} out={out:.6f} avg={out / dx:.6f} K'={P.F(xp):.8f} "
              f"spot after={P.spot(xp, i, j):.6f}")

    section("5 slippage USDC->USDT (bps) by sharpness R, vs Curve")
    sizes = (1, 5, 10, 20, 30, 38, 40, 45)
    Rs = (10, 30, 100, 1000)
    pools = {R: WeightedFermi(ratio=R) for R in Rs}
    print("  size  Curve " + " ".join(f"R={R:<6}" for R in Rs))
    for s in sizes:
        row = " ".join(f"{bps(pools[R].out(X0, 0, 1, s), s):8.2f}" for R in Rs)
        print(f"  {s:4}  {bps(curve_fn(X0, 0, 1, s, 0.0), s):6.2f} {row}")

    section("5b slippage USDT->USDC (bps)")
    for s in (1, 5, 10, 15, 19, 20, 25):
        row = " ".join(f"{bps(pools[R].out(X0, 1, 0, s), s):8.2f}" for R in Rs)
        print(f"  {s:4}  {bps(curve_fn(X0, 1, 0, s, 0.0), s):6.2f} {row}")

    section("6 dumping NEW into USDC, R=10 vs R=100")
    for s in (0.5, 1, 1.1, 1.5, 2, 5, 50):
        print(f"  dx={s:5}  out R=10 {P.out(X0, 2, 0, s):.4f}  "
              f"out R=100 {pools[100].out(X0, 2, 0, s):.4f}  Curve {curve_fn(X0, 2, 0, s, 0.0):.4f}")

    section("7 Curve at rest on the same balances")
    for i, j in ((2, 0), (1, 0)):
        print(f"  Curve p({COINS[i]}->{COINS[j]}) = {curve_spot(X0, i, j, A_LIVE):.6f}")
    xp, paid, taken = attack(curve_fn, X0, 2, 1.0, 0.0)
    print(f"  arbs sell NEW until price 1: NEW in {taken:.2f}, goods out {paid:.2f}, "
          f"balances {[round(x, 2) for x in xp]}")

    section("8 hack to $0, greedy arbitrage, total LP loss")
    for bad in range(3):
        for name, fn in (("Curve", curve_fn), ("Fermi R=10", P.out), ("Fermi R=100", pools[100].out)):
            _, paid, taken = attack(fn, X0, bad, 0.0, 0.0)
            total = paid + X0[bad]
            print(f"  {COINS[bad]:5s} {name:12s} held {X0[bad]:6.2f} + paid out {paid:7.2f} "
                  f"= {total:7.2f} ({total / V:6.2%})  formula w*c = {W[bad] * P.c[bad]:.2f}")

    section("9 ratio footgun: NEW on R=3, others R=10")
    bad = WeightedFermi(ratios=[10, 10, 3])
    p = bad.spot(X0, 2, 0)
    print(f"  f'_NEW(V)={bad.fp(2, V):.7f}  p(NEW->USDC) at target = {p:.6f}  "
          f"= {abs(1 - p) * 1e4:.0f} bps off peg")


if __name__ == "__main__":
    main()
