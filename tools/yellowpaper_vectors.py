"""Test vectors and property checks for docs/yellow-paper.md.

Every number quoted in the yellow paper is printed by this script. It also
fuzzes the two global claims (invariant preserved by every swap, and the
state-independent loss floor of Theorem 4) over random swap sequences.

    python3 tools/yellowpaper_vectors.py
"""

import math
import random

LN2 = math.log(2.0)


def softplus(z):
    """ln(1 + e^z), evaluated with exp only on non-positive arguments."""
    return max(z, 0.0) + math.log1p(math.exp(-abs(z)))


def softplus_inv(a):
    """Inverse of softplus for a > 0: a + ln(1 - e^-a)."""
    if a <= 0:
        raise ValueError("softplus_inv domain is a > 0")
    return a + math.log(-math.expm1(-a))


class Pool:
    """Balanced Fermi-Dirac pool: sum_i w_i f_i(x_i / w_i) = K.

    Parameters are stored relative to the scale V so the curve is
    1-homogeneous in (x, V): c_i = V (1 + b_i), T_i = V b_i / R.
    """

    def __init__(self, x, b, R, V=None, w=None):
        self.V = V if V is not None else sum(x)
        self.w = w if w is not None else [xi / self.V for xi in x]
        self.b = list(b)
        self.R = R
        self.x = list(x)
        self.K = self.F(self.x)

    # per-coin parameters -------------------------------------------------
    def c(self, i):
        return self.V * (1 + self.b[i])

    def T(self, i):
        return self.V * self.b[i] / self.R

    # transform -----------------------------------------------------------
    def f(self, i, r):
        return -self.T(i) * softplus((self.c(i) - r) / self.T(i))

    def fp(self, i, r):
        z = (r - self.c(i)) / self.T(i)
        return math.exp(-z) / (1 + math.exp(-z)) if z > 0 else 1 / (1 + math.exp(z))

    def g(self, i, u):
        if u >= 0:
            return math.inf
        return self.c(i) - self.T(i) * softplus_inv(-u / self.T(i))

    def term(self, i, xi):
        return self.w[i] * self.f(i, xi / self.w[i])

    def F(self, x):
        return sum(self.term(i, xi) for i, xi in enumerate(x))

    def eps(self, i, xi):
        """Wall penalty w_i T_i softplus((r_i - c_i)/T_i) >= 0."""
        r = xi / self.w[i]
        return self.w[i] * self.T(i) * softplus((r - self.c(i)) / self.T(i))

    def spot(self, i, j, x=None):
        x = x or self.x
        return self.fp(i, x[i] / self.w[i]) / self.fp(j, x[j] / self.w[j])

    # swaps ---------------------------------------------------------------
    def rest(self, x, i, j):
        return sum(self.term(k, x[k]) for k in range(len(x)) if k not in (i, j))

    def out_given_in(self, i, j, dx, x=None):
        x = x or self.x
        u = (self.K - self.rest(x, i, j) - self.term(i, x[i] + dx)) / self.w[j]
        xj_new = self.w[j] * self.g(j, u)
        if xj_new <= 0:
            raise ArithmeticError("output reserve would be non-positive")
        return x[j] - xj_new

    def in_given_out(self, i, j, dy, x=None):
        x = x or self.x
        u = (self.K - self.rest(x, i, j) - self.term(j, x[j] - dy)) / self.w[i]
        if u >= 0:
            raise ArithmeticError("requested output exceeds capacity")
        return self.w[i] * self.g(i, u) - x[i]

    def capacity(self, i, j, x=None):
        """sup over dx of out_given_in: the input coin's term -> 0."""
        x = x or self.x
        u = (self.K - self.rest(x, i, j)) / self.w[j]
        return x[j] - self.w[j] * self.g(j, u)

    def apply(self, i, j, dx):
        dy = self.out_given_in(i, j, dx)
        self.x[i] += dx
        self.x[j] -= dy
        return dy

    # closed forms --------------------------------------------------------
    def K_closed(self):
        sw_b = sum(wi * bi for wi, bi in zip(self.w, self.b))
        return -self.V * sw_b * softplus(self.R) / self.R

    def eps0(self):
        sw_b = sum(wi * bi for wi, bi in zip(self.w, self.b))
        return self.V * sw_b * softplus(-self.R) / self.R

    def C(self):
        return self.K + sum(self.w[i] * self.c(i) for i in range(len(self.w)))


def section(t):
    print(f"\n[{t}]")


NAMES = ("USDC", "USDT", "NEW")
X0 = [100.0, 50.0, 10.0]
B0 = [0.40, 0.40, 0.10]


def main():
    p = Pool(X0, B0, R=10)
    n = len(X0)

    section("Y1 parameters and K")
    for i in range(n):
        print(f"  {NAMES[i]:5s} w={p.w[i]:.4f} b={p.b[i]:.2f} c={p.c(i):.1f} "
              f"T={p.T(i):.2f} wall={p.w[i]*p.c(i):.2f} room={p.w[i]*p.c(i)-X0[i]:.2f}")
    print(f"  K direct      = {p.K:.8f}")
    print(f"  K closed form = {p.K_closed():.8f}")
    print(f"  phi = f'(V)   = {1/(1+math.exp(-10)):.10f}")
    print(f"  eps0          = {p.eps0():.8f}")
    print(f"  C = K + sum wc = {p.C():.8f}")

    section("Y2 balanced-form identity  sum x - sum w*eps = C")
    lhs = sum(X0) - sum(p.eps(i, X0[i]) for i in range(n))
    print(f"  at target: {lhs:.8f}")

    section("Y3 exact-in, exact-out, capacity")
    dy = p.out_given_in(0, 1, 5.0)
    print(f"  5 USDC in -> USDT out           = {dy:.6f}")
    dx = p.in_given_out(0, 1, dy)
    print(f"  round trip: USDC in for that out = {dx:.6f}")
    dx2 = p.in_given_out(0, 1, 5.0)
    print(f"  USDC in for exactly 5 USDT out   = {dx2:.6f}")
    for i, j in ((0, 1), (1, 0), (2, 0)):
        print(f"  capacity {NAMES[i]}->{NAMES[j]} = {p.capacity(i, j):.6f}")
    try:
        p.in_given_out(2, 0, 1.5)
    except ArithmeticError as e:
        print(f"  NEW in for 1.5 USDC out -> revert: {e}")

    section("Y4 homogeneity  F(lx; lV) = l F(x; V)")
    for lam in (2.0, 10.0, 0.001):
        q = Pool([lam * v for v in X0], B0, R=10)
        print(f"  lambda={lam:<6} K={q.K:.8f}  lambda*K={lam*p.K:.8f}  "
              f"spot USDC->USDT={q.spot(0, 1):.10f}")

    section("Y5 proportional deposit of 25%")
    q = Pool(X0, B0, R=10)
    q.apply(0, 1, 5.0)  # start from an off-target state
    s_before = [q.spot(0, 1), q.spot(2, 0)]
    lam = 1.25
    q.x = [lam * v for v in q.x]
    q.V *= lam
    print(f"  F(new x; new V) = {q.F(q.x):.8f}   lambda*K = {lam*q.K:.8f}")
    print(f"  spots before {s_before[0]:.10f} {s_before[1]:.10f}")
    print(f"  spots after  {q.spot(0,1):.10f} {q.spot(2,0):.10f}")

    section("Y6 Theorem 4 bound: good reserves >= C - w_h c_h")
    for h in range(n):
        floor = p.C() - p.w[h] * p.c(h)
        q = Pool(X0, B0, R=10)
        goods = [k for k in range(n) if k != h]
        # greedy: dump h in small chunks into whichever good coin pays more
        for _ in range(4000):
            best = max(goods, key=lambda k: q.spot(h, k))
            if q.spot(h, best) < 1e-12:
                break
            q.apply(h, best, 0.05)
        good_left = sum(q.x[k] for k in goods)
        paid = sum(X0[k] for k in goods) - good_left
        print(f"  {NAMES[h]:5s} paid out={paid:.6f} room={p.w[h]*p.c(h)-X0[h]:.6f} "
              f"good left={good_left:.6f} bound={floor:.6f} "
              f"total loss={X0[h]+paid:.6f} cap={p.w[h]*p.c(h)+p.eps0():.6f}")

    section("Y7 no-drain condition  w_j > sum_{k!=j} w_k b_k")
    for j in range(n):
        s = sum(p.w[k] * p.b[k] for k in range(n) if k != j)
        print(f"  {NAMES[j]:5s} w_j={p.w[j]:.4f} sum others w*b={s:.4f} "
              f"-> {'guaranteed' if p.w[j] > s else 'NOT guaranteed (contract must revert)'}")

    section("Y8 fuzz: invariant and Theorem 4 over random paths")
    rng = random.Random(7)
    worst_K, worst_margin, reverts, swaps = 0.0, math.inf, 0, 0
    for trial in range(300):
        q = Pool(X0, B0, R=rng.choice([10, 30, 100]))
        for _ in range(60):
            i, j = rng.sample(range(n), 2)
            dx = rng.expovariate(1 / 8.0)
            try:
                q.apply(i, j, dx)
                swaps += 1
            except ArithmeticError:
                reverts += 1
                continue
            worst_K = max(worst_K, abs(q.F(q.x) - q.K))
            for h in range(n):
                good = sum(q.x[k] for k in range(n) if k != h)
                margin = good - (q.C() - q.w[h] * q.c(h))
                worst_margin = min(worst_margin, margin)
    print(f"  swaps={swaps} reverts={reverts}")
    print(f"  max |F - K|          = {worst_K:.3e}")
    print(f"  min Theorem-4 margin = {worst_margin:.3e}  (>= 0 up to float rounding)")

    section("Y9 ratio mismatch at rest (NEW on R=3)")
    # R is per-pool in this spec; emulate a per-coin mismatch directly
    phi10 = 1 / (1 + math.exp(-10))
    phi3 = 1 / (1 + math.exp(-3))
    print(f"  p(NEW->USDC) = {phi3/phi10:.6f}  -> {(1-phi3/phi10)*1e4:.0f} bps off peg")


if __name__ == "__main__":
    main()
