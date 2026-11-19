"""Weighted Fermi-Dirac AMM: unequal target weights per coin.

The symmetric invariant sum f(x_i) = n f(x_m) forces every coin to the same
target reserve. That is wrong for a basket holding a lot of a reputable stable
and only a little of a new one. Normalising each reserve by its target weight
fixes it:

    F(x_1..x_n) = sum_i  w_i * f(x_i / w_i) = K ,   r_i = x_i / w_i

The outer w_i and the inner 1/w_i cancel under differentiation, so
dF/dx_i = f'(r_i) and the spot price is f'(r_i)/f'(r_j). At target every r_i
equals the pool scale V, so every pair quotes 1:1 despite unequal raw balances.

Each coin's absolute cap becomes w_i * c, so its worst-case loss scales with its
weight. That is the knob for holding an untrusted coin at small size.

    python3 tools/weighted_fermi.py
"""

import math

V = 1000.0                      # pool scale: every coin sits at r_i = V on target
BUDGET = 0.30                   # fraction above the peg the pool will still pay near par
RATIO = 10.0                    # (c - V) / T, same near-par choice as the other docs
WEIGHTS = {"USDC": 0.60, "USDT": 0.30, "NEWUSD": 0.10}

CAP = V * (1.0 + BUDGET)
TEMP = (CAP - V) / RATIO


def f(r):
    """Fermi transform of a normalised reserve, via a stable softplus."""
    u = (CAP - r) / TEMP
    return -TEMP * (max(u, 0.0) + math.log1p(math.exp(-abs(u))))


def f_prime(r):
    """Points one unit of this coin contributes to the invariant."""
    return 1.0 / (1.0 + math.exp((r - CAP) / TEMP))


def target(weights=WEIGHTS):
    return {k: w * V for k, w in weights.items()}


def invariant(xp, weights=WEIGHTS):
    return sum(weights[k] * f(xp[k] / weights[k]) for k in xp)


def spot(xp, i, j, weights=WEIGHTS):
    """Price of coin i quoted in coin j."""
    return f_prime(xp[i] / weights[i]) / f_prime(xp[j] / weights[j])


def loss_cap(k, weights=WEIGHTS):
    """Worst-case LP loss if coin k goes to zero: what is held plus what arbs can add."""
    held = weights[k] * V
    cap = weights[k] * CAP
    return held, cap - held, cap


# ------------------------------------------- per-coin budgets (decoupled exposure)

def params(budget, ratio=RATIO):
    """Cap and sharpness for one coin. Holding ratio fixed keeps f'(V) identical."""
    c = V * (1.0 + budget)
    return c, (c - V) / ratio


def f_i(r, c, T):
    u = (c - r) / T
    return -T * (max(u, 0.0) + math.log1p(math.exp(-abs(u))))


def fp_i(r, c, T):
    return 1.0 / (1.0 + math.exp((r - c) / T))


def spot_i(xp, i, j, W, P):
    """Price with per-coin transforms: f_i'(r_i) / f_j'(r_j)."""
    return fp_i(xp[i] / W[i], *P[i]) / fp_i(xp[j] / W[j], *P[j])


def cap_from_loss(L, w):
    """Invert loss_cap: given a desired dollar loss cap L, return (c, b, T)."""
    if L <= w * V:
        raise ValueError(f"loss cap {L} must exceed what is already held ({w*V})")
    c = L / w
    return c, c / V - 1.0, (c - V) / RATIO


def demo_per_coin_budgets():
    """Tighten only the risky coin, keeping every pair at exactly 1:1."""
    B = {"USDC": 0.30, "USDT": 0.30, "NEWUSD": 0.10}
    P = {k: params(B[k]) for k in WEIGHTS}
    tgt = target()
    print("\nPER-COIN BUDGETS, ratio held at %.0f" % RATIO)
    hdr = (f"  {'coin':8s} {'w':>5s} {'b_i':>5s} {'c_i':>7s} {'T_i':>5s} "
           f"{'ratio':>6s} {'slope at V':>11s} {'loss cap':>9s}")
    print(hdr)
    for k, w in WEIGHTS.items():
        c, T = P[k]
        print(f"  {k:8s} {w:5.2f} {B[k]:5.0%} {c:7.0f} {T:5.0f} {(c-V)/T:6.1f} "
              f"{fp_i(V, c, T):11.7f} {w*c/V:8.0%}")
    print("  prices at target:")
    for a in WEIGHTS:
        for b in WEIGHTS:
            if a != b:
                print(f"    p({a:7s} -> {b:7s}) = {spot_i(tgt, a, b, WEIGHTS, P):.7f}")


def demo_ratio_footgun():
    """Mismatched ratios leave the pool off peg with zero trades."""
    bad = {"USDC": (0.30, 10.0), "NEWUSD": (0.10, 3.0)}
    P = {k: params(b, r) for k, (b, r) in bad.items()}
    print("\nFOOTGUN: per-coin budget with MISMATCHED ratio")
    for k, (b, r) in bad.items():
        c, T = P[k]
        print(f"  {k:8s} b={b:.0%} ratio={r:>4.0f}  c={c:.0f} T={T:.1f}  "
              f"slope at V = {fp_i(V, c, T):.7f}")
    W2 = {k: WEIGHTS[k] for k in bad}
    tgt2 = {k: W2[k] * V for k in bad}
    p = spot_i(tgt2, "NEWUSD", "USDC", W2, P)
    print(f"  p(NEWUSD -> USDC) at target = {p:.6f}  ->  {abs(p-1)*10000:.0f} bps off peg at rest")
    print("  rule: keep (c_i - V) / T_i identical across coins")


def demo_loss_cap_api():
    """Parameterise by the dollar loss cap, which is the quantity LPs care about."""
    print("\nPARAMETERISE BY DESIRED LOSS CAP")
    print(f"  {'coin':8s} {'w':>5s} {'target L':>9s} {'=> c_i':>8s} {'=> b_i':>7s} {'=> T_i':>7s}")
    for k, L in (("USDC", 780.0), ("USDT", 390.0), ("NEWUSD", 110.0)):
        w = WEIGHTS[k]
        c, b, T = cap_from_loss(L, w)
        print(f"  {k:8s} {w:5.2f} {L:9.1f} {c:8.0f} {b:7.0%} {T:7.1f}")
    print(f"  constraint: L_i > w_i * V, since you cannot cap below what you already hold")


def main():
    slope = "f'(r)"
    print(f"Weighted Fermi.  V={V:.0f}  budget={BUDGET:.0%}  cap c={CAP:.0f}  T={TEMP:.0f}")
    print("F = sum_i w_i f(x_i / w_i) = K\n")

    tgt = target()
    print("TARGET STATE")
    print(f"{'coin':8s} {'weight':>7s} {'target x':>9s} {'r=x/w':>8s} {slope:>10s} {'cap w*c':>9s}")
    for k, w in WEIGHTS.items():
        print(f"{k:8s} {w:7.2f} {tgt[k]:9.1f} {tgt[k]/w:8.1f} "
              f"{f_prime(tgt[k]/w):10.6f} {w*CAP:9.1f}")
    print(f"\nK = {invariant(tgt):.6f}")

    print("\nSPOT PRICES AT TARGET")
    for a in WEIGHTS:
        for b in WEIGHTS:
            if a != b:
                print(f"  p({a:7s} -> {b:7s}) = {spot(tgt, a, b):.8f}")

    print("\nDUMPING NEWUSD, priced in USDC")
    print(f"{'x_NEWUSD':>9s} {'r':>8s} {slope:>13s} {'price':>13s}")
    for x in (100.0, 110.0, 120.0, 130.0, 140.0, 160.0, 200.0):
        xp = dict(tgt, NEWUSD=x)
        print(f"{x:9.1f} {x/WEIGHTS['NEWUSD']:8.0f} "
              f"{f_prime(x/WEIGHTS['NEWUSD']):13.3e} {spot(xp, 'NEWUSD', 'USDC'):13.3e}")

    print("\nWORST-CASE LOSS PER COIN")
    for k in WEIGHTS:
        held, budget, total = loss_cap(k)
        print(f"  {k:8s} held {held:6.1f} + drain budget {budget:6.1f} = "
              f"{total:6.1f}  ({total/V:5.1%} of TVL)")

    demo_per_coin_budgets()
    demo_ratio_footgun()
    demo_loss_cap_api()


if __name__ == "__main__":
    main()
