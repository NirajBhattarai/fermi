"""Local interactive 3D view of the Fermi-Dirac AMM invariant for an n-coin pool.

Desmos 3D can only show three reserves because it has three axes. This uses a
symmetry reduction instead: two coins are dumped into the pool with free
reserves x and y, and the remaining n-2 good coins are held at a common
reserve z. The invariant then collapses to a surface

    f(x) + f(y) + (n-2) f(z) = n f(xm)   =>   z = g( (n f(xm) - f(x) - f(y)) / (n-2) )

which is plottable for any n. Writes a self-contained HTML file that works
offline; the slider steps n from 3 to 20.

    python3 tools/fermi_viz.py
"""

import numpy as np
import plotly.graph_objects as go

XM, C, T = 10.0, 13.0, 0.3   # peg, cap, sharpness
W, V = 2.0, 3.0              # flat-band half-width and tail scale
N_RANGE = (3, 4, 5, 6, 7, 8, 10, 12, 16, 20)
GRID = 90


# ---------------------------------------------------------------- Fermi-Dirac

def fermi_f(x):
    """-T ln(1 + e^((c-x)/T)), via a stable softplus."""
    u = (C - x) / T
    return -T * (np.maximum(u, 0.0) + np.log1p(np.exp(-np.abs(u))))


def fermi_g(u):
    """Inverse of fermi_f. Defined only for u < 0; returns NaN elsewhere.

    c - T ln(e^(-u/T) - 1) is rearranged to c + u - T ln(1 - e^(u/T)) so the
    exponential never overflows for strongly negative u.
    """
    u = np.asarray(u, dtype=float)
    out = np.full(u.shape, np.nan)
    ok = u < 0
    out[ok] = C + u[ok] - T * np.log1p(-np.exp(u[ok] / T))
    return out


# ------------------------------------------------------------------ flat band

def band_f(x):
    x = np.asarray(x, dtype=float)
    lo, hi = XM - W, XM + W
    return np.where(
        x < lo, lo + V * np.log(np.maximum(x - lo + V, 1e-12) / V),
        np.where(x <= hi, x, hi + V * np.log(np.maximum(x - hi + V, 1e-12) / V)),
    )


def band_g(u):
    u = np.asarray(u, dtype=float)
    lo, hi = XM - W, XM + W
    return np.where(
        u < lo, lo - V + V * np.exp((u - lo) / V),
        np.where(u <= hi, u, hi - V + V * np.exp((u - hi) / V)),
    )


# ------------------------------------------------------------------- surfaces

def fermi_surface(n, X, Y):
    return fermi_g((n * fermi_f(XM) - fermi_f(X) - fermi_f(Y)) / (n - 2))


def band_surface(n, X, Y):
    return band_g((n * XM - band_f(X) - band_f(Y)) / (n - 2))


def fermi_floor(n):
    """Reserve each good coin settles at once both dumped coins are unbounded."""
    return float(fermi_g(np.array([n * fermi_f(XM) / (n - 2)]))[0])


def band_floor(_n):
    return XM - W - V


def payout(n, floor):
    """Total good coins the pool hands over, summed across the n-2 good coins."""
    return (n - 2) * (XM - floor)


# ----------------------------------------------------------------------- plot

def build():
    # Dense near the peg where Fermi turns over, sparse out to 6x peg. The flat
    # band's tail is logarithmic, so it needs a wide range before the two
    # designs visibly separate.
    g = np.unique(np.concatenate([
        np.linspace(XM - 2.0, XM + 10.0, GRID),
        np.linspace(XM + 10.0, XM + 50.0, GRID // 2),
    ]))
    X, Y = np.meshgrid(g, g)
    corners = np.array([g[0], g[-1]])
    solid = lambda col: [[0.0, col], [1.0, col]]
    # Surfaces take 1-D x/y with a 2-D z, which keeps the embedded JSON small.
    trim = lambda Z: np.round(Z, 4)

    def traces(n):
        # Plot what an LP actually cares about: total good coins handed over,
        # summed across the n-2 good coins. Fermi saturates at 2(c-xm) for every
        # n, so its surface is a plateau; the flat band's grows as 5(n-2).
        Pf = trim((n - 2) * (XM - fermi_surface(n, X, Y)))
        Pb = trim((n - 2) * (XM - band_surface(n, X, Y)))
        cap = np.full((2, 2), round(payout(n, fermi_floor(n)), 4))
        hover = ("depegged coin 1 %{x:.2f}<br>depegged coin 2 %{y:.2f}"
                 "<br>pool pays out %{z:.2f}")
        return [
            go.Surface(x=g, y=g, z=Pf, colorscale=solid("#26a269"), showscale=False,
                       name="Fermi-Dirac", showlegend=True,
                       hovertemplate=hover + "<extra>Fermi-Dirac</extra>"),
            go.Surface(x=corners, y=corners, z=cap, colorscale=solid("#c01c28"),
                       showscale=False, opacity=0.45,
                       name="Fermi cap", showlegend=True,
                       hovertemplate="cap %{z:.2f}<extra>Fermi cap</extra>"),
            go.Surface(x=g, y=g, z=Pb, colorscale=solid("#1a5fb4"), showscale=False,
                       opacity=0.55, name="Flat band", showlegend=True,
                       hovertemplate=hover + "<extra>Flat band</extra>"),
            go.Scatter3d(x=[XM], y=[XM], z=[0.0], mode="markers",
                         marker=dict(size=5, color="black"),
                         name="peg", showlegend=True,
                         hovertemplate="peg, nothing paid out<extra></extra>"),
        ]

    def frame_layout(n):
        fc = payout(n, fermi_floor(n))
        bc = payout(n, band_floor(n))
        worst = float(np.nanmax((n - 2) * (XM - band_surface(n, X, Y))))
        return go.Layout(
            title=dict(text=f"Two coins depeg in an n = {n} pool. "
                            f"Fermi-Dirac pays {fc:.2f} however far the dump goes; "
                            f"the flat band pays {worst:.1f} by the edge of this range "
                            f"and tends to {bc:.0f}."
                            "<br><sub>Height is the total good coins the pool pays out. "
                            "Green is Fermi-Dirac, red is its cap, blue is the flat band. "
                            "Drag to rotate; use the legend to isolate a surface.</sub>"),
            scene=dict(zaxis=dict(range=[0, max(9.0, 1.1 * worst)])),
        )

    n0 = 10
    fig = go.Figure(
        data=traces(n0),
        frames=[go.Frame(data=traces(n), name=str(n), layout=frame_layout(n))
                for n in N_RANGE],
    )

    steps = []
    for n in N_RANGE:
        ff, bf = fermi_floor(n), band_floor(n)
        steps.append(dict(
            method="animate", label=str(n),
            args=[[str(n)], dict(mode="immediate", frame=dict(duration=0, redraw=True),
                                 transition=dict(duration=0))],
        ))
        at6x = (n - 2) * (XM - float(band_surface(n, np.array([XM + 50.0]),
                                                  np.array([XM + 50.0]))[0]))
        print(f"  n={n:<3} Fermi pays {payout(n, ff):5.2f} (capped)   |   "
              f"flat band pays {at6x:6.2f} at 6x peg, {payout(n, bf):6.2f} in the limit"
              f"   |   ratio at 6x peg {at6x / payout(n, ff):4.1f}x")

    fig.update_layout(frame_layout(n0))
    fig.update_layout(
        scene=dict(
            xaxis_title="reserve of depegged coin 1",
            yaxis_title="reserve of depegged coin 2",
            zaxis_title="total good coins paid out",
            camera=dict(eye=dict(x=1.75, y=1.75, z=0.75)),
            aspectmode="cube",
        ),
        sliders=[dict(active=list(N_RANGE).index(n0), pad=dict(t=55),
                      currentvalue=dict(prefix="coins in pool  n = "), steps=steps)],
        margin=dict(l=0, r=0, t=90, b=0), height=820,
    )
    return fig


def build_slide():
    """Static 2-D summary: total LP payout against pool size, both designs."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    ns = np.arange(3, 21)
    far = np.array([XM + 50.0])
    fermi = [payout(n, fermi_floor(n)) for n in ns]
    band6 = [(n - 2) * (XM - float(band_surface(n, far, far)[0])) for n in ns]
    bandinf = [payout(n, band_floor(n)) for n in ns]

    fig, ax = plt.subplots(figsize=(9, 5.2), dpi=200)
    ax.plot(ns, bandinf, color="#1a5fb4", ls=":", lw=2,
            label="flat band, unbounded dump")
    ax.plot(ns, band6, color="#1a5fb4", lw=2.5, marker="o", ms=4,
            label="flat band, dump to 6x peg")
    ax.plot(ns, fermi, color="#26a269", lw=3.5, marker="o", ms=4,
            label="Fermi-Dirac, any dump size")
    ax.set_xlabel("coins in the pool, n")
    ax.set_ylabel("total good coins the pool pays out")
    ax.set_title("Two coins depeg: what the pool loses\n"
                 f"Fermi-Dirac is pinned at {payout(3, fermi_floor(3)):.0f} "
                 "= 2(c - xm) for every n", fontsize=11)
    ax.set_xticks(ns)
    ax.grid(alpha=0.25)
    ax.legend(frameon=False, fontsize=9)
    fig.tight_layout()
    out = "graphs/fermi-payout-vs-n.png"
    fig.savefig(out)
    return out


if __name__ == "__main__":
    print(f"xm={XM}  c={C}  T={T}  |  flat band w={W} v={V}\n")
    fig = build()
    out = "graphs/fermi-dirac-3d.html"
    fig.write_html(out, include_plotlyjs=True, full_html=True)
    print(f"\nwrote {out}  (self-contained, opens offline)")
    print(f"wrote {build_slide()}  (static summary for slides)")
