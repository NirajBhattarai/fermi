"""Plot: dollar LP loss on the live-sized 3pool, Curve vs Fermi, across depeg severity.

Left panel  - total LP loss split into the part the curve design controls
              (AMM-caused) and the part no invariant can avoid (junk already held).
Right panel - the cost side: slippage versus trade size.

    python3 tools/fermi_savings_plot.py   ->  graphs/fermi-vs-curve-savings.png
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).parent.parent / "graphs" / "fermi-vs-curve-savings.png"

TVL, PER_COIN = 158.66, 52.89

# AMM-caused loss, in $M, from tools/curve_vs_fermi_sim.py on a balanced pool
PEXT = [0.00, 0.50, 0.88, 0.97]
AMM_LOSS = {
    "Curve A=4000": [105.77, 49.40, 11.04, 2.49],
    "Fermi b=30%": [15.87, 6.83, 1.32, 0.26],
    "Fermi b=20%": [10.58, 4.56, 0.88, 0.17],
    "Fermi b=10%": [5.29, 2.27, 0.44, 0.09],
}
COLOR = {
    "Curve A=4000": "#c01c28",
    "Fermi b=30%": "#e08f00",
    "Fermi b=20%": "#26a269",
    "Fermi b=10%": "#1a5fb4",
}

# slippage in bps, same source
SIZES = [1, 5, 10, 25, 40]
SLIP = {
    "Curve A=4000": [0.05, 0.24, 0.49, 1.52, 4.41],
    "Fermi b=30%": [0.30, 3.08, 38.72, 3655.70, 6033.56],
    "Fermi b=20%": [0.46, 10.63, 483.39, 5769.14, 7355.71],
    "Fermi b=10%": [1.15, 483.39, 4711.49, 7884.57, 8677.85],
}


def unavoidable(p):
    return PER_COIN * (1.0 - p)


def main():
    fig, (ax, bx) = plt.subplots(1, 2, figsize=(14, 6))
    names = list(AMM_LOSS)
    idx = np.arange(len(PEXT))
    width = 0.2

    for k, name in enumerate(names):
        off = (k - (len(names) - 1) / 2) * width
        amm = AMM_LOSS[name]
        una = [unavoidable(p) for p in PEXT]
        ax.bar(idx + off, amm, width, color=COLOR[name], label=f"{name} (AMM-caused)")
        ax.bar(idx + off, una, width, bottom=amm, color=COLOR[name],
               alpha=0.28, hatch="//", edgecolor="white", linewidth=0)
        for i, (a, u) in enumerate(zip(amm, una)):
            ax.text(i + off, a + u + 2.0, f"{a + u:.0f}", ha="center",
                    fontsize=7, color=COLOR[name])

    ax.axhline(TVL, color="black", ls=":", lw=1)
    ax.text(len(PEXT) - 0.45, TVL + 3, f"TVL ${TVL:.2f}M", fontsize=8, ha="right")
    ax.set_xticks(idx)
    ax.set_xticklabels([f"${p:.2f}" for p in PEXT])
    ax.set_xlabel("external price of the failing coin")
    ax.set_ylabel("LP loss, $M")
    ax.set_title("Total LP loss on a $158.66M pool\nsolid = AMM-caused, hatched = unavoidable inventory")
    ax.legend(fontsize=8, loc="upper right")
    ax.grid(axis="y", alpha=0.25)

    for name in names:
        bx.plot(SIZES, SLIP[name], "o-", color=COLOR[name], label=name)
    bx.set_yscale("log")
    bx.axhline(10, color="grey", ls=":", lw=1)
    bx.text(40, 11, "10 bps", fontsize=8, ha="right", color="grey")
    bx.set_xlabel("trade size, $M")
    bx.set_ylabel("slippage, bps (log scale)")
    bx.set_title("What the protection costs\nsame knob sets both")
    bx.legend(fontsize=8, loc="lower right")
    bx.grid(alpha=0.25, which="both")

    fig.suptitle("Fermi-Dirac vs Curve StableSwap: dollar loss and the depth it costs", fontsize=12)
    fig.tight_layout()
    fig.savefig(OUT, dpi=150)
    print(f"wrote {OUT}")

    print("\nsavings vs Curve A=4000, AMM-caused loss ($M)")
    for name in names[1:]:
        row = [AMM_LOSS["Curve A=4000"][i] - AMM_LOSS[name][i] for i in range(len(PEXT))]
        print(f"  {name:14s} " + "  ".join(f"{v:7.2f}" for v in row))


if __name__ == "__main__":
    main()
