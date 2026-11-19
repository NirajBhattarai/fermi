"""Plot: good coins left in a $158.7M 3-coin pool as a hacked coin is dumped.

    python3 tools/curve_vs_fermi_plot.py   ->  graphs/curve-vs-fermi-drain.png
"""

import sys
from pathlib import Path

import matplotlib.pyplot as plt

sys.path.insert(0, str(Path(__file__).parent))
from curve_vs_fermi_sim import A_LIVE, FEE_LIVE, LIVE, N, RATIO, curve_out, make_fermi  # noqa: E402

TVL = sum(LIVE.values())
BAL = [TVL / N] * N
OUT = Path(__file__).parent.parent / "graphs" / "curve-vs-fermi-drain.png"


def path(out_fn, max_junk=140.0, step=0.25):
    xp, xs, ys = list(BAL), [0.0], [sum(BAL[1:])]
    dumped = 0.0
    while dumped < max_junk:
        dy, j = max((out_fn(xp, 0, k, step, FEE_LIVE), k) for k in (1, 2))
        xp[0] += step
        xp[j] -= dy
        dumped += step
        xs.append(dumped)
        ys.append(xp[1] + xp[2])
    return xs, ys


SERIES = [  # label, colour (validated categorical slots 1-5), linestyle, out_fn
    ("Curve A=4000 (live)", "#2a78d6", "--", lambda *a: curve_out(*a[:4], A_LIVE, a[4])),
    ("Curve A=300", "#eb6834", "--", lambda *a: curve_out(*a[:4], 300, a[4])),
    ("Fermi, 30% budget", "#1baf7a", "-", make_fermi(TVL / N, 0.3, RATIO, BAL).out),
    ("Fermi, 20% budget", "#eda100", "-", make_fermi(TVL / N, 0.2, RATIO, BAL).out),
    ("Fermi, 10% budget", "#e87ba4", "-", make_fermi(TVL / N, 0.1, RATIO, BAL).out),
]

fig, ax = plt.subplots(figsize=(10, 6), dpi=150)
fig.patch.set_facecolor("#fcfcfb")
ax.set_facecolor("#fcfcfb")
for label, colour, ls, fn in SERIES:
    xs, ys = path(fn)
    ax.plot(xs, ys, color=colour, lw=2, ls=ls, label=label)
    ax.annotate(f"{label}: \\${ys[-1]:.1f}M left", (xs[-1], ys[-1]), xytext=(6, 0),
                textcoords="offset points", va="center", fontsize=8.5, color="#3b3b38")

ax.set_xlim(0, 215)
ax.set_ylim(-3, 112)
ax.set_xlabel("Hacked coin dumped into pool (\\$M face value)", color="#3b3b38")
ax.set_ylabel("Good coins left in pool (\\$M, both legs)", color="#3b3b38")
ax.set_title("One coin of a \\$158.7M 3-coin pool is hacked to \\$0: how much good liquidity survives",
             loc="left", fontsize=11, color="#1d1d1b")
ax.grid(color="#e4e3dd", lw=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
for s in ("left", "bottom"):
    ax.spines[s].set_color("#b5b4ab")
ax.tick_params(colors="#5f5e58")
ax.legend(frameon=False, loc="lower left", fontsize=9)
fig.tight_layout()
fig.savefig(OUT, facecolor=fig.get_facecolor())
print("wrote", OUT)
