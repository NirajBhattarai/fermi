# Fermi

A Uniswap v4 hook for multi-stablecoin baskets built on the **balanced Fermi–Dirac
invariant**:

$$
\sum_i w_i\, f_i\!\left(\frac{x_i}{w_i}\right) = K,
\qquad
f_i(r) = -T_i \ln\!\left(1 + e^{(c_i - r)/T_i}\right)
$$

It quotes 1:1 at a deliberately unequal target mix, trades near constant-sum below
each coin's wall, and caps LP loss from any failed coin at $w_h c_h$, independent of
how much of it is dumped. On the live Curve 3pool state, a one-coin hack costs Curve
LPs 100%. The same pool on Fermi with a 30% budget loses 43%.

## Monorepo layout

```
fermi/
├── contracts/            Foundry project (Uniswap v4 hook)
│   ├── src/              hook contracts (currently the template Counter hook)
│   ├── test/             Foundry tests + v4 test utilities
│   ├── script/           deploy / pool / liquidity / swap scripts
│   └── lib/              submodules: forge-std, OpenZeppelin uniswap-hooks, hookmate
├── web/                  React 19 + TypeScript frontend (Vite)
├── docs/yellow-paper.md  formal specification
├── tools/                Python simulators
├── graphs/               Fermi–Dirac Desmos files, HTML plots and figures
├── package.json          root scripts (pnpm workspace)
└── pnpm-workspace.yaml
```

| Path | Contents |
|---|---|
| `contracts/` | Foundry project: the Fermi hook, tests and deployment scripts |
| `web/` | Frontend app for interacting with Fermi pools |
| `docs/yellow-paper.md` | **Formal specification**: definitions, theorems, state transitions, fixed-point and v4 hook rules, test vectors |
| `tools/` | Python simulators; every number in the docs comes from one of these |
| `graphs/` | Fermi–Dirac Desmos files (`.des`), HTML plots and figures |

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, solc 0.8.30)
- Node.js 20+ and [pnpm](https://pnpm.io/installation) 10+
- Python 3 with `numpy` and `matplotlib` (only for the plotting tools)

## Getting started

```bash
git clone --recurse-submodules https://github.com/NirajBhattarai/fermi.git
cd fermi
pnpm install
```

If you cloned without submodules: `git submodule update --init --recursive`.

## Scripts

Run from the repo root:

| Command | What it does |
|---|---|
| `pnpm dev` | Start the web app at http://localhost:5173 |
| `pnpm build` | Type-check and build the web app |
| `pnpm lint` | Lint the web app (oxlint) |
| `pnpm contracts:build` | `forge build` in `contracts/` |
| `pnpm contracts:test` | `forge test` in `contracts/` |

Or work in a package directly:

```bash
cd contracts && forge build && forge test
cd web && pnpm dev
```

## Research tools

```bash
python3 tools/yellowpaper_vectors.py   # yellow-paper test vectors + fuzz
python3 tools/curve_vs_fermi_sim.py    # Curve 3pool comparison
```

Run them from the repo root, since they write to `graphs/`.

## License

[MIT](LICENSE)
