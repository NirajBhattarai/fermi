# Fermi Brand Guidelines v1.0

> Last updated: 2026-11-19 · Status: Draft
> Evidence: `reports/DeFi protocol site introductions.md`

## Quick reference

| Element | Value |
|---|---|
| Primary message | Stablecoin baskets with a floor. |
| Category | Uniswap v4 hook for multi-stablecoin pools |
| Accent | Wall amber: `#f5b544` dark / `#a35f00` light |
| Display font | Newsreader (serif, italic for math) |
| Body font | IBM Plex Sans |
| Numbers | IBM Plex Mono, tabular |
| Voice | Precise, candid, calm |

Design tokens live in `web/src/index.css` (`:root`, with a light-scheme override). That file is the token source of truth. Don't fork it into another token file.

---

## 1. Positioning

**Positioning statement.** Fermi is the stablecoin pool for LPs and integrators who want to know the worst case before they deposit. Unlike Curve StableSwap or a plain v4 pool, it fixes the most a failed coin can cost LPs at deployment and proves that bound (yellow paper, Theorem T4).

**Value proposition.** For LPs who hold several stablecoins and can't rule out one of them failing, Fermi is a Uniswap v4 hook that quotes near 1:1 like a stable pool. Its difference: LP loss from any one failed coin is capped at `w·(1 + b)` of the pool, whatever the size of the dump.

**The gap we own.** No surveyed competitor puts a number on depeg loss on its landing page. That covers Curve, Balancer, Fluid, Mento, Uniswap's StablePair hook and the math-led protocols. Competitors sell the calm case. We lead with the bad case and its ceiling.

## 2. Message architecture

| Message | Audience need | Proof point |
|---|---|---|
| If one coin fails, your loss has a ceiling. | LPs: tail risk | T4, §4; Y6 test vector; 3pool case 43% |
| Near 1:1 below each coin's wall. | Traders: price | T2; 5 USDC → 4.999631 USDT (Y3) |
| An unequal target mix still trades at par. | Curators | T1; 100 / 50 / 10 basket |
| Closed-form swaps and capacity. | Integrators | §6.1, T5; no Newton iteration |
| Everything here is reproducible. | Judges, reviewers | `tools/yellowpaper_vectors.py`; this app matches Y1–Y7 |

**Pitches**

- **10 seconds:** Stablecoin baskets with a floor. If one coin fails, LPs lose at most what was set at deployment.
- **30 seconds:** Stable pools like Curve have no floor. If one coin dies, arbitrageurs drain the good coins until LPs hold only the dead one. Fermi is a Uniswap v4 hook whose curve puts a wall behind every coin. Below the wall it trades near 1:1, and past it the pool stops absorbing. The yellow paper proves that a failed coin costs at most `w·(1 + b)`.
- **60 seconds:** The 30-second pitch, plus the proof points: the 3pool case (43% versus no floor), closed-form swaps, and the honest status (simulation only, unaudited).

## 3. Voice

| Trait | Means | Do | Don't |
|---|---|---|---|
| Precise | Every claim has a number and a condition | "LP loss ≤ w·(1 + b), for any dump size" | "Maximum protection" |
| Candid | Name the risk before the benefit | "Unaudited. Not deployed." | Hide status in the footer |
| Calm | Research-lab tone, not hype | "The pool refuses what it can't absorb." | "Revolutionary", "next-gen", emoji |

**Words to avoid:** safe, protected, guaranteed, risk-free, no loss, secure (unless qualified and proven).
**Words to use:** bounded, capped, floor, wall, budget, proved, reproducible.

**Rules**

- Lead with the outcome. "Uniswap v4 hook" is the category line, not the headline.
- State the theorem as a conditional bound, and link its section in the paper.
- Put status ("Research prototype · Simulation only · Unaudited · Not deployed") at the same weight as the claim.
- Never imply Fermi has volume or TVL. Ecosystem stats must be labelled and sourced.
- Describe Curve as having "no floor: loss keeps growing toward the whole pool as the dump grows", never as a bare "100%".

**Sample rewrite**

- Before: "Fermi protects LPs from depegs."
- After: "If any one coin fails, LP loss is capped at that coin's weight × (1 + budget), fixed at deployment and proved in T4."

## 4. Visual identity

- **Colour:** one accent, amber, which means *the wall*. Semantic colours mark state only: good means verified or within the bound, bad means no floor or a revert, accent-soft means a status warning. Coin series use `--c0` to `--c4`.
- **Type:**
  - Headlines in Newsreader at weight 400, with italics for emphasis and math.
  - UI text in IBM Plex Sans.
  - Every number in IBM Plex Mono with tabular figures.
- **Mark:** an S-curve (the Fermi–Dirac step) in amber inside a rounded square, with a dotted vertical line at the wall. Always use it on `--surface-2`.
- **Imagery:** real charts of the invariant only. No stock 3D coins, neon gradients or glows.
- **Motion:** purposeful only (see the animation rules in this repo's history). Never animate numbers.

## 5. Consistency checklist

- [ ] Each number matches the yellow paper or is computed live from `web/src/lib/fermi.ts`
- [ ] The status line appears on every page that shows a benefit claim
- [ ] No word from the avoid list appears
- [ ] Claims link to their theorem or section
- [ ] Comparison rows cite a source
