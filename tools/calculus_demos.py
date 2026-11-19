"""Numeric demos behind docs/calculus-primer.md.

Derivatives by finite difference, integrals by trapezoid rule, and the two AMM
cases that matter here: rebuilding the Fermi transform f from its slope, and
showing why the spot price (a derivative) diverges from the actual fill (an
integral along the curve) as trade size grows.

    python3 tools/calculus_demos.py
"""

import math

C, T = 13.0, 0.3          # Fermi cap and sharpness, same as fermi_viz.py
X0, Y0 = 100.0, 100.0     # Uniswap demo reserves


def line(title):
    print("\n" + "=" * 62 + f"\n{title}\n" + "=" * 62)


def deriv(f, x, h=1e-6):
    """Central difference: nudge either side and measure the slope."""
    return (f(x + h) - f(x - h)) / (2 * h)


def integrate(f, a, b, n=200000):
    """Trapezoid rule: slice the span, add the thin trapezoids."""
    h = (b - a) / n
    s = 0.5 * (f(a) + f(b))
    for k in range(1, n):
        s += f(a + k * h)
    return s * h


# ------------------------------------------------------------------ P1, P2, P3

def demo_derivatives():
    line("P1  Derivative by finite difference")
    cases = [
        ("x^2  at x=3   (exact 2x = 6)", lambda x: x * x, 3.0, 6.0),
        ("x^3  at x=2   (exact 3x^2 = 12)", lambda x: x ** 3, 2.0, 12.0),
        ("sin x at x=0  (exact cos 0 = 1)", math.sin, 0.0, 1.0),
        ("ln x at x=5   (exact 1/x = 0.2)", math.log, 5.0, 0.2),
        ("e^x  at x=1   (exact e)", math.exp, 1.0, math.e),
    ]
    for name, f, x, exact in cases:
        print(f"  {name:38s} numeric={deriv(f, x):.6f}  exact={exact:.6f}")


def demo_integrals():
    line("P2  Integral by trapezoid rule = area under the curve")
    cases = [
        ("speed 60 for 2 hours -> distance", lambda t: 60.0, 0, 2, 120.0),
        ("speed = 2t from 0..3 -> distance", lambda t: 2 * t, 0, 3, 9.0),
        ("x^2 from 0..3", lambda x: x * x, 0, 3, 9.0),
        ("1/x from 1..e", lambda x: 1 / x, 1, math.e, 1.0),
        ("sin x from 0..pi", math.sin, 0, math.pi, 2.0),
    ]
    for name, f, a, b, exact in cases:
        print(f"  {name:38s} numeric={integrate(f, a, b):.6f}  exact={exact:.6f}")


def demo_fundamental_theorem():
    line("P3  Differentiating and integrating undo each other")
    f, fp = lambda x: x ** 3, lambda x: 3 * x * x
    a, b = 1.0, 4.0
    print(f"  f(x)=x^3,  f(4)-f(1)                  = {f(b) - f(a):.4f}")
    print(f"  integral of f'(x)=3x^2 from 1 to 4   = {integrate(fp, a, b):.4f}")
    print("  -> accumulating the rate rebuilds the total change")


# ---------------------------------------------------------------------- P4

def demo_gradient_descent():
    line("P4  Derivative as a tool: gradient descent")
    cost = lambda x: (x - 7) ** 2 + 3          # minimum at x = 7
    x = 0.0
    for step in range(1, 41):
        g = deriv(cost, x)
        x -= 0.1 * g
        if step in (1, 2, 5, 10, 20, 40):
            print(f"  step {step:2d}: x={x:.6f}  slope={g:+.6f}  cost={cost(x):.6f}")
    print("  slope -> 0 at the bottom; this is how solvers and Newton's method land")


# ---------------------------------------------------------------------- P5

def fermi_slope(x):
    return 1.0 / (1.0 + math.exp((x - C) / T))


def fermi_f(x):
    return -T * math.log(1.0 + math.exp((C - x) / T))


def demo_fermi_rebuild():
    line("P5  Fermi AMM: integrate the chosen slope to rebuild f")
    base = 10.0
    for x in (10.0, 12.0, 13.0, 14.0, 20.0):
        rebuilt = fermi_f(base)
        if x > base:
            rebuilt += integrate(fermi_slope, base, x, 100000)
        print(f"  x={x:5.1f}  f'(x)={fermi_slope(x):.6f}   "
              f"f closed={fermi_f(x):+.6f}   f rebuilt={rebuilt:+.6f}")
    print(f"  f' is ~1 below the cap c={C:g} and ~0 above it, so f flattens")
    print("  that flattening is the loss floor")


# ---------------------------------------------------------------------- P6

def demo_spot_vs_fill():
    line("P6  Partial derivatives: why spot price is not the actual fill")
    k = X0 * Y0
    dfdx, dfdy = Y0, X0        # F = xy  =>  dF/dx = y, dF/dy = x
    spot = dfdx / dfdy
    print(f"  reserves x={X0:g}, y={Y0:g},  K={k:g}")
    print(f"  dF/dx={dfdx:g}  dF/dy={dfdy:g}  spot={spot:.6f} y per x")
    print("\n  trade size   spot estimate     exact fill        error")
    for dx in (0.01, 1.0, 10.0, 50.0):
        exact = Y0 - k / (X0 + dx)
        print(f"  {dx:9.2f}   {spot * dx:13.6f}   {exact:13.6f}   {spot * dx - exact:+.6f}")
    print("  tiny trade -> the derivative is the price")
    print("  big trade  -> integrate along the curve; the gap is slippage")


if __name__ == "__main__":
    demo_derivatives()
    demo_integrals()
    demo_fundamental_theorem()
    demo_gradient_descent()
    demo_fermi_rebuild()
    demo_spot_vs_fill()
