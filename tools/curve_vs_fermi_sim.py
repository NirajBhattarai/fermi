"""Curve StableSwap (exact 3pool contract maths) vs Fermi-Dirac AMM under a depeg/hack.

Units are $M. Curve maths follow StableSwap3Pool.vy: Ann = A * N (contract A),
which equals whitepaper A_wp = A / N**(N-1). Swap fee is taken from the output.

Attack model: the depegged coin trades at external price p_ext. Arbitrageurs
sell it into the pool (greedy, small chunks, always into the good coin that
pays more) until the pool's marginal price for it falls to p_ext.

    LP loss caused by the AMM = good coins paid out - p_ext * junk taken in
    (unavoidable loss = junk the pool already held * (1 - p_ext))

    python3 tools/curve_vs_fermi_sim.py
"""

import math

N = 3
LIVE = {"DAI": 26.2915, "USDC": 27.0058, "USDT": 105.3587}   # Curve API, 2026-11-16
A_LIVE, FEE_LIVE = 4000, 0.00015                              # on-chain A(), fee()
RATIO = 10.0                                                  # (c - xm) / T


# ------------------------------------------------------------------ StableSwap

def get_D(xp, A):
    Ann, S, D = A * N, sum(xp), sum(xp)
    for _ in range(255):
        D_P = D
        for x in xp:
            D_P = D_P * D / (x * N)
        Dp = D
        D = (Ann * S + D_P * N) * D / ((Ann - 1) * D + (N + 1) * D_P)
        if abs(D - Dp) < 1e-12 * D:
            break
    return D


def get_y(i, j, x, xp, A, D):
    """New balance of coin j when coin i is set to x, holding D."""
    Ann, c, S = A * N, D, 0.0
    for k in range(N):
        if k == j:
            continue
        xk = x if k == i else xp[k]
        S += xk
        c = c * D / (xk * N)
    c = c * D / (Ann * N)
    b = S + D / Ann
    y = D
    for _ in range(255):
        yp = y
        y = (y * y + c) / (2 * y + b - D)
        if abs(y - yp) < 1e-15 * max(y, 1e-30):
            break
    return y


def curve_out(xp, i, j, dx, A, fee):
    D = get_D(xp, A)
    dy = xp[j] - get_y(i, j, xp[i] + dx, xp, A, D)
    return dy * (1 - fee)


def curve_spot(xp, i, j, A):
    h = max(xp[i], 1e-9) * 1e-7
    return curve_out(xp, i, j, h, A, 0.0) / h


# ------------------------------------------------------------------ Fermi-Dirac

def softplus(z):
    return max(z, 0.0) + math.log1p(math.exp(-abs(z)))


class Fermi:
    """sum f(x_i) = K,  f(x) = -T ln(1 + e^((c-x)/T)),  f'(x) = 1/(1+e^((x-c)/T))."""

    def __init__(self, c, T, xp):
        self.c, self.T = c, T
        self.K = sum(self.f(x) for x in xp)

    def f(self, x):
        return -self.T * softplus((self.c - x) / self.T)

    def fp(self, x):
        z = (x - self.c) / self.T
        return math.exp(-z) / (1 + math.exp(-z)) if z > 0 else 1 / (1 + math.exp(z))

    def g(self, u):
        if u >= 0:
            return math.inf
        a = -u / self.T                          # ln(e^a - 1) without overflow
        return self.c - self.T * (a + math.log(-math.expm1(-a)))

    def out(self, xp, i, j, dx, fee):
        rest = sum(self.f(xp[k]) for k in range(N) if k not in (i, j))
        y = self.g(self.K - rest - self.f(xp[i] + dx))
        return max(xp[j] - y, 0.0) * (1 - fee)

    def spot(self, xp, i, j):
        return self.fp(xp[i]) / self.fp(xp[j])


# ------------------------------------------------------------------ attack

def attack(out_fn, xp, bad, p_ext, fee, max_in=1e5):
    """Greedy dump of coin `bad` until marginal pool price <= p_ext."""
    xp = list(xp)
    goods = [k for k in range(N) if k != bad]
    paid, taken, step = 0.0, 0.0, 1.0
    while taken < max_in and step > 1e-7:
        best, j = max((out_fn(xp, bad, k, step, fee), k) for k in goods)
        if best <= p_ext * step or best <= 0:
            step /= 4
            continue
        xp[bad] += step
        xp[j] -= best
        paid += best
        taken += step
        step = min(step * 1.5, 0.5)
    return xp, paid, taken


def report(name, out_fn, xp0, bad, p_ext, fee, labels):
    xp, paid, taken = attack(out_fn, xp0, bad, p_ext, fee)
    amm_loss = paid - p_ext * taken
    unavoid = xp0[bad] * (1 - p_ext)
    left = ", ".join(f"{labels[k]} {xp[k]:.2f}" for k in range(N) if k != bad)
    print(f"  {name:<22} junk in {taken:8.2f}  goods out {paid:7.2f}  "
          f"AMM loss {amm_loss:7.2f}  (+unavoidable {unavoid:5.2f})  left: {left}")
    return amm_loss


def make_fermi(xm, budget, ratio, xp):
    """Cap c = xm(1+budget); sharpness T chosen so (c - xm)/T = ratio (project: 3/0.3 = 10)."""
    return Fermi(xm * (1 + budget), xm * budget / ratio, xp)


def fermi_matching(xp_curve, A, budget, temp):
    """Fermi pool with same TVL and the same marginal prices as the Curve state."""
    tvl, xm = sum(xp_curve), sum(xp_curve) / N
    c, T = xm * (1 + budget), xm * budget / temp
    ref = min(range(N), key=lambda k: xp_curve[k])         # most-wanted coin = numeraire
    prices = [1.0 if k == ref else curve_spot(xp_curve, k, ref, A) for k in range(N)]

    def state(xr):                                         # x_k from f'(x_k)/f'(xr) = p_k
        out = []
        for k in range(N):
            target = prices[k] * (1 / (1 + math.exp((xr - c) / T)))
            target = min(max(target, 1e-300), 1 - 1e-16)
            out.append(c + T * math.log(1 / target - 1))
        return out

    lo, hi = 1e-6, c                                       # solve sum(x) = TVL for xr
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sum(state(mid)) < tvl else (lo, mid)
    return state((lo + hi) / 2), c, T


def main():
    labels = list(LIVE)
    live = list(LIVE.values())
    tvl = sum(live)
    bal = [tvl / N] * N

    print(f"Live 3pool: {LIVE}  TVL {tvl:.2f}  A={A_LIVE} (contract) = "
          f"{A_LIVE / N ** (N - 1):.0f} whitepaper, fee {FEE_LIVE:.4%}")
    print("Live spot prices (vs DAI):",
          {labels[k]: round(curve_spot(live, k, 0, A_LIVE), 6) for k in range(1, N)})

    # ---- 1. doc table check: drain one good, third coin fixed
    print("\n[1] One-good drain, third fixed, balanced 52.89 each. spot of hacked:")
    for frac in (0.5, 0.2, 0.1, 0.05, 0.02, 0.01, 0.001):
        row = []
        for A in (A_LIVE, A_LIVE * N ** (N - 1), 300):
            D = get_D(bal, A)
            y = bal[1] * frac
            lo, hi = bal[0], bal[0] * 50                   # find x giving that y
            for _ in range(200):
                mid = (lo + hi) / 2
                lo, hi = (mid, hi) if get_y(0, 1, mid, bal, A, D) > y else (lo, mid)
            xp = [lo, y, bal[2]]
            row.append(f"A={A}: X {lo:6.2f} p {curve_spot(xp, 0, 1, A):.4f}")
        print(f"  Y left {frac:>6.1%}  " + " | ".join(row))

    # ---- 2. near-peg service quality
    print("\n[2] Slippage selling USDC->USDT on a balanced pool, no fee (bps):")
    fermis = {b: make_fermi(tvl / N, b, RATIO, bal) for b in (0.1, 0.2, 0.3)}
    for size in (1, 5, 10, 25, 40):
        cs = (1 - curve_out(bal, 1, 2, size, A_LIVE, 0) / size) * 1e4
        fs = "  ".join(f"Fermi b={b:.0%}: {(1 - F.out(bal, 1, 2, size, 0) / size) * 1e4:8.2f}"
                       for b, F in fermis.items())
        print(f"  ${size:>3}M  Curve: {cs:8.2f}  {fs}")

    # ---- 3. hacks on a balanced pool
    for p_ext in (0.0, 0.5, 0.88, 0.97):
        print(f"\n[3] Balanced pool, coin 0 depegs to ${p_ext}:")
        report("Curve A=4000", lambda *a: curve_out(*a[:4], A_LIVE, a[4]), bal, 0, p_ext, FEE_LIVE, labels)
        report("Curve A=300", lambda *a: curve_out(*a[:4], 300, a[4]), bal, 0, p_ext, FEE_LIVE, labels)
        for b, F in fermis.items():
            report(f"Fermi budget {b:.0%}", F.out, bal, 0, p_ext, FEE_LIVE, labels)

    # ---- 4. hacks on the LIVE pool, vs a Fermi pool at the same prices
    for b in (0.1, 0.3):
        fx, c, T = fermi_matching(live, A_LIVE, b, RATIO)
        F = Fermi(c, T, fx)
        print(f"\n[4] Fermi twin of live pool (budget {b:.0%}, same TVL & prices): "
              + ", ".join(f"{labels[k]} {fx[k]:.2f}" for k in range(N)) + f"  cap c={c:.2f}")
        for bad in range(N):
            print(f" {labels[bad]} hacked to $0:")
            report("Curve live", lambda *a: curve_out(*a[:4], A_LIVE, a[4]), live, bad, 0.0, FEE_LIVE, labels)
            report("Fermi twin", F.out, fx, bad, 0.0, FEE_LIVE, labels)
            report("Fermi, balanced start", fermis[b].out, bal, bad, 0.0, FEE_LIVE, labels)


if __name__ == "__main__":
    main()
