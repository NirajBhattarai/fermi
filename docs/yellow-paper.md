# The Balanced Fermi–Dirac AMM — Yellow Paper

**Draft v0.1 · 2026-11-19**

A formal specification of a multi-stablecoin AMM whose invariant is

$$
\boxed{\;F(\mathbf{x}) \;=\; \sum_{i=1}^{n} w_i\, f_i\!\left(\frac{x_i}{w_i}\right) \;=\; K\;}
\qquad
f_i(r) = -T_i \ln\!\left(1 + e^{(c_i - r)/T_i}\right)
$$

It quotes 1:1 at a deliberately **unequal** target mix, swaps near constant-sum below
each coin's wall, and bounds LP loss from any failed coin by a constant fixed at
deployment. This bound holds whatever the path, the starting state or the size of
the dump.

This document states the definitions, theorems, state transitions and
implementation rules a conforming implementation must follow. The explanatory notes
are elsewhere: `fermi-dirac-derivation.md` (where the invariant comes from),
`weighted-fermi.md` (why the weights appear twice), `fermi-from-scratch.md` (one pool
traced end to end) and `curve-vs-fermi-depeg-drain.md` (comparison with Curve). Every
number in §12 is printed by `tools/yellowpaper_vectors.py`.

---

## 1. Notation and conventions

| Symbol | Domain | Meaning |
|---|---|---|
| $n$ | $\mathbb{N}, n \ge 2$ | number of coins in the basket |
| $x_i$ | $\mathbb{R}_{>0}$ | curve reserve of coin $i$, in common units (§8.1) |
| $w_i$ | $(0,1)$, $\sum w_i = 1$ | target weight of coin $i$ |
| $V$ | $\mathbb{R}_{>0}$ | pool scale: total reserves at the balanced state |
| $r_i = x_i / w_i$ | $\mathbb{R}_{>0}$ | normalised reserve |
| $b_i$ | $\mathbb{R}_{>0}$ | budget of coin $i$: how far past target it may go at ~par, as a fraction of $V$ |
| $R$ | $\mathbb{R}_{>0}$ | sharpness ratio, **one value per pool** |
| $c_i = V(1+b_i)$ | | cap (wall) of coin $i$ in normalised units |
| $T_i = V b_i / R$ | | temperature (transition width) of coin $i$ |
| $K$ | $\mathbb{R}_{<0}$ | invariant level |
| $\sigma(z) = \ln(1+e^z)$ | | softplus |
| $\varphi = (1+e^{-R})^{-1}$ | | slope of every $f_i$ at the balanced state |

"Wall" of coin $i$ means the absolute reserve $w_i c_i$. The "room" of coin $i$ in
state $\mathbf{x}$ is $w_i c_i - x_i$.

Parameters $(w_i, b_i, R)$ are dimensionless and stored. $V$ and $K$ are state
variables that change only through liquidity operations (§6.3). $c_i$ and $T_i$ are
derived from $V$ every time they are used and are never stored on their own.

---

## 2. The transform

### 2.1 Definitions

For each coin, with $c = c_i$, $T = T_i$:

$$
f(r) = -T\,\sigma\!\left(\frac{c - r}{T}\right),
\qquad
f'(r) = \frac{1}{1 + e^{(r-c)/T}},
\qquad
f''(r) = -\frac{f'(r)\,(1 - f'(r))}{T}
$$

$f'$ is the Fermi–Dirac occupancy with chemical potential $c$ and temperature $T$.
The inverse on the range $f(r) < 0$ is

$$
g(u) = f^{-1}(u) = c - T\,\sigma^{-1}\!\left(-\frac{u}{T}\right),
\qquad
\sigma^{-1}(a) = a + \ln\!\left(1 - e^{-a}\right),\quad a > 0
$$

### 2.2 Properties

| # | Property | Consequence |
|---|---|---|
| P1 | $f < 0$ everywhere, $f(r) \to 0^-$ as $r \to \infty$ | a coin's contribution is bounded above, so dumping it buys a bounded amount |
| P2 | $0 < f' < 1$, strictly decreasing | every coin is worth strictly less than 1 unit of $F$ per unit; value falls monotonically with inventory |
| P3 | $f'' < 0$ | $f$ is strictly concave (§4, T3) |
| P4 | $f(r) = (r - c) - T\sigma\!\left(\frac{r - c}{T}\right)$ | exact split into a linear part and a wall penalty (from $\sigma(z) = z + \sigma(-z)$) |
| P5 | $f'(c) = \tfrac12$ | at the wall a coin trades at half value |

P4 is the identity the main results depend on. It says that $f$ is constant-sum minus
a non-negative penalty, and the penalty is exponentially small below the wall.

---

## 3. The balanced invariant

### 3.1 Definition

$$
F(\mathbf{x};\,V) = \sum_{i=1}^n w_i\, f_i\!\left(\frac{x_i}{w_i}\right)
$$

A swap is valid if and only if it maps a state with $F = K$ to another state with
$F = K$, all reserves stay positive, and the rounding rules of §8.3 hold.

### 3.2 Balanced state

**Definition.** The pool is *balanced* when $r_i = V$ for every $i$, that is, when
$x_i = w_i V$.

Raw balances differ from coin to coin, but normalised balances are all equal. That is
the sense in which a 100 / 50 / 10 basket is "balanced".

### 3.3 Closed form for $K$

At the balanced state each normalised reserve sits $R$ temperatures below its wall,
since $(c_i - V)/T_i = R$ for every coin. So $f_i(V) = -T_i\,\sigma(R)$ and

$$
\boxed{K = -\,\frac{\sigma(R)}{R}\; V \sum_{i} w_i b_i}
$$

### 3.4 Homogeneity

Since $c_i$ and $T_i$ are both proportional to $V$,

$$
F(\lambda\mathbf{x};\, \lambda V) = \lambda\, F(\mathbf{x};\, V)
\qquad \forall \lambda > 0
$$

and the spot prices (§4) are invariant under this scaling. Proportional deposits and
withdrawals therefore leave every price unchanged (§6.3).

### 3.5 Balanced form (exact)

Apply P4 to every term and define the **wall penalty**

$$
\varepsilon_i(x_i) = w_i T_i\, \sigma\!\left(\frac{r_i - c_i}{T_i}\right) > 0
$$

Then the invariant can be written, with no approximation, as

$$
\boxed{\;\sum_i x_i \;-\; \sum_i \varepsilon_i(x_i) \;=\; C,
\qquad C := K + \sum_i w_i c_i = V - \varepsilon_0\;}
$$

$$
\varepsilon_0 = \sum_i \varepsilon_i(w_i V) = \frac{\sigma(-R)}{R}\, V \sum_i w_i b_i
\;\approx\; e^{-R}\, V\! \sum_i w_i b_i / R
$$

Read it as: **constant sum, minus a penalty that is about zero below each wall and
grows linearly past it.** Every behavioural result below follows from this line.

---

## 4. Theorems

### T1 — Peg at balance

$$
\frac{\partial F}{\partial x_i} = w_i \cdot f_i'(r_i) \cdot \frac{1}{w_i} = f_i'(r_i)
\quad\Rightarrow\quad
p_{i\to j} = \frac{f_i'(r_i)}{f_j'(r_j)}
$$

At the balanced state $f_i'(V) = (1 + e^{-(c_i - V)/T_i})^{-1} = \varphi$ for every
$i$, so $p_{i \to j} = 1$ for all pairs.

*Necessity of the outer $w_i$.* Without it, $p_{i\to j} = w_j / w_i$ at target, which
is a standing arbitrage.

*Necessity of a shared $R$.* $f_i'(V)$ depends only on the ratio $(c_i - V)/T_i$. If
coin $i$ used its own ratio $R_i \ne R_j$, then
$p_{i \to j} = (1 + e^{-R_j})/(1 + e^{-R_i}) \ne 1$ at rest. That is why this
specification defines $T_i = V b_i / R$ with a single pool-level $R$, so a mismatch
cannot be configured. (Example: $R_i = 3$ against $R_j = 10$ gives 474 bps off peg at
rest.)

### T2 — Near-constant-sum swaps

Consider a swap that puts $\Delta$ of coin $i$ in and takes $\Delta_{\text{out}}$ of
coin $j$ out. Then, by §3.5,

$$
\Delta_{\text{out}} \;=\; \Delta \;-\; \underbrace{\bigl[\varepsilon_i(x_i + \Delta) - \varepsilon_i(x_i)\bigr]}_{\ge 0}
\;-\; \underbrace{\bigl[\varepsilon_j(x_j) - \varepsilon_j(x_j - \Delta_{\text{out}})\bigr]}_{\ge 0}
$$

Hence:

1. $\Delta_{\text{out}} \le \Delta$. Before fees, no swap ever returns more than it
   receives.
2. The shortfall is at most $\varepsilon_i(x_i + \Delta)$, and since
   $\sigma(z) \le e^{z}$,
   $$
   \text{slippage} \;\le\; \frac{w_i T_i}{\Delta}\, \exp\!\left(\frac{r_i' - c_i}{T_i}\right),
   \qquad r_i' = \frac{x_i + \Delta}{w_i}
   $$

This decays exponentially in the distance from the wall measured in temperatures.
Raising $R$ makes the pool flat up to the wall without moving the peg (T1).

### T3 — Concavity and monotone pricing

$F$ is a sum of strictly concave functions of one variable, so it is strictly
concave. Its upper level sets are convex, and along any two-coin swap path the price
$p_{i\to j}$ strictly decreases as coin $i$ is added. Consequences:

- the fill for an exact input is at most spot × size, so there is no negative slippage
  on a single swap;
- for a fixed $\Delta$, splitting a trade into pieces cannot produce more output
  (path-additivity of a level-set AMM).

### T4 — Loss floor (path-independent)

**Theorem.** Let $\mathbf{x}$ be **any** state with $F(\mathbf{x}; V) = K$. For any
set of coins $S \subsetneq \{1,\ldots,n\}$,

$$
\boxed{\;\sum_{k \notin S} x_k \;>\; C - \sum_{h \in S} w_h c_h
\;=\; V\Bigl(1 - \sum_{h\in S} w_h(1+b_h)\Bigr) - \varepsilon_0\;}
$$

*Proof.* By P4, $x_h - \varepsilon_h(x_h) = w_h\bigl(c_h + f_h(r_h)\bigr) < w_h c_h$,
because $f_h < 0$ (P1). Rearranging §3.5,

$$
\sum_{k\notin S} x_k
= C - \sum_{h \in S}\bigl(x_h - \varepsilon_h\bigr) + \sum_{k \notin S}\varepsilon_k
> C - \sum_{h\in S} w_h c_h . \qquad\blacksquare
$$

The bound does not depend on the sequence of swaps, on the starting skew, or on how
much of the coins in $S$ was minted. Its only inputs are the parameters and $V$.

**Corollary (single failure).** If coin $h$ goes to zero value, LP value falls from
$V$ (balanced) to at least $V - w_h c_h - \varepsilon_0$:

$$
\text{LP loss} \;\le\; w_h c_h + \varepsilon_0 \;=\; w_h V (1 + b_h) + \varepsilon_0
$$

The bound is tight. As the dump goes to infinity, $f_h \to 0$ and the good coins'
penalties fall to $\approx 0$, so the loss converges to $w_h c_h$ plus a vanishing
correction. It splits into the inventory already held, $x_h$, and the good coins paid
out, $\text{room}_h$.

**Corollary (multiple failures).** For a failed set $S$, the loss is at most
$\min\bigl(V,\; \sum_{h\in S} w_h c_h + \varepsilon_0\bigr)$. The bound stops binding
once $\sum_{S} w_h(1+b_h) \ge 1$.

### T5 — Capacity (maximum output)

For the pair $i \to j$ in state $\mathbf{x}$, the supremum of output over all input
sizes is reached as coin $i$'s term goes to $0^-$:

$$
\text{cap}_{i\to j}(\mathbf{x}) = x_j - w_j\, g_j\!\left(\frac{K - \sum_{k\ne i,j} w_k f_k(r_k)}{w_j}\right)
$$

It is a closed form, so routers can query it in $O(n)$ before splitting an order.

### T6 — No-drain condition

Apply T4 with $S = \{k \ne j\}$:

$$
x_j > V\Bigl(w_j - \sum_{k \ne j} w_k b_k\Bigr) - \varepsilon_0
$$

If $w_j - \sum_{k\ne j} w_k b_k > \varepsilon_0 / V$, coin $j$ can never be drained,
whatever happens. If it fails for some $j$, the reserve of $j$ can reach zero only
after **every** other coin has gone past its wall. A conforming implementation must
then revert any swap that would make $x_j \le 0$ (§8.4). It must never wrap around or
clamp.

---

## 5. Parameterisation

### 5.1 Inputs

A pool is fully specified by:

1. **Weights** $w_i$, from the target mix: $w_i = x_i^{\text{target}} / V$.
2. **Loss caps** $L_i$ (fractions of $V$), the per-coin risk a curator accepts. The
   budget is derived from it:
   $$
   b_i = \frac{L_i}{w_i} - 1
   $$
3. **Sharpness** $R$, shared by the pool.

### 5.2 Constraints (enforced at initialisation)

| Constraint | Reason |
|---|---|
| $\sum_i w_i = 1$, $w_i > 0$ | definition of weights |
| $L_i > w_i$ (equivalently $b_i > 0$) | a coin's loss cannot be capped below what the pool already holds of it |
| $R \ge 8$ | $\varphi \ge 0.99966$, so the peg sits within 3.4 bps of par at rest (`curve-vs-fermi-depeg-drain.md` §6.2) |
| $R \le R_{\max}$ (implementation-defined, §8.2) | $T_i$ must stay representable, and $\exp$ must not lose all precision across the wall |
| no-drain for every $j$ (T6): *recommended*, not required | when it is violated, the revert path of §8.4 is reachable |

### 5.3 Effect of each dial

| Dial | Hack loss (T4) | Everyday depth (T2) |
|---|---|---|
| $w_i \downarrow$ | $\downarrow$ (inventory and room both scale) | less of coin $i$ held at par |
| $b_i \downarrow$ | $\downarrow$ (room only) | the wall comes closer: one-way flow past $w_i V b_i$ is refused |
| $R \uparrow$ | unchanged | flatter up to the wall, sharper cliff at it |

Depth and protection are set by the same quantity, $w_i V b_i$. This is the trade-off
of the design, not an implementation artefact (`fermi-vs-curve-savings.md` §5).

---

## 6. State transitions

State: $\Sigma = (\mathbf{x}, V, K, \text{totalShares}, \text{fees}, \text{flags})$.

### 6.1 Swap, exact input

Input: $i$, $j$, $\Delta > 0$, fee rate $\gamma$.

1. $\Delta_{\text{net}} = \Delta(1 - \gamma)$. The fee $\gamma\Delta$ goes to
   $\text{fees}_i$, **outside** $\mathbf{x}$ (§6.4).
2. $x_i' = x_i + \Delta_{\text{net}}$.
3. $\text{rest} = \sum_{k \ne i,j} w_k f_k(r_k)$.
4. $u = \bigl(K - \text{rest} - w_i f_i(x_i'/w_i)\bigr) / w_j$. Since $f_i$ is
   increasing, $w_j u = w_j f_j(r_j) - \bigl[w_i f_i(r_i') - w_i f_i(r_i)\bigr] < w_j f_j(r_j) < 0$,
   so $u$ always lies in the domain of $g_j$.
5. $x_j' = w_j\, g_j(u)$. **Revert** if $x_j' \le x_{\min}$.
6. $\Delta_{\text{out}} = x_j - x_j'$, rounded down (§8.3).
7. Commit $\mathbf{x}'$. Post-condition: $F(\mathbf{x}') \ge K$ when evaluated with
   the implementation's own rounding.

No iteration is needed. This is one $\ln$/$\exp$ pair per coin touched, plus the
cached `rest` (§8.5).

### 6.2 Swap, exact output

Input: $i$, $j$, $\Delta_{\text{out}} > 0$.

1. $x_j' = x_j - \Delta_{\text{out}}$. Revert if $x_j' \le x_{\min}$.
2. $u = \bigl(K - \text{rest} - w_j f_j(x_j'/w_j)\bigr) / w_i$.
3. **Revert** if $u \ge 0$. The request exceeds $\text{cap}_{i\to j}$ (T5); no finite
   input pays for it.
4. $\Delta_{\text{net}} = w_i\, g_i(u) - x_i$, rounded up.
   $\Delta = \lceil \Delta_{\text{net}} / (1-\gamma) \rceil$.

### 6.3 Liquidity

Only **proportional** operations are defined. Let $\lambda = 1 + \delta$.

| Operation | Effect |
|---|---|
| Add, $\delta > 0$ | depositor supplies $\delta x_i$ of every coin (current ratios, not target ratios); $\mathbf{x} \leftarrow \lambda\mathbf{x}$, $V \leftarrow \lambda V$, $K \leftarrow \lambda K$; mints $\delta \cdot \text{totalShares}$ |
| Remove, share $s$ | pays out $s \cdot x_i$ of every coin, junk included; $\mathbf{x}$, $V$, $K$ scaled by $1 - s$ |

By §3.4 these operations move no price, so they cannot be sandwiched. Deposit amounts
round up and withdrawals round down.

A single-sided deposit is equivalent to a swap followed by a proportional add. If it
is offered at all, it must be implemented as exactly that composition and pay the swap
fee and slippage. It must not be priced at par.

### 6.4 Fees

Fees accrue in $\text{fees}_i$ and never enter $\mathbf{x}$. If they entered the curve
reserves, they would raise $F$ above $K$ and silently use up the room of whichever coin
the flow favours. Fees are compounded by a proportional add (§6.3) funded from
$\text{fees}$. Whatever part is not in current proportions stays in $\text{fees}$.
With this rule, T4 holds net of fees, and fees only add to LP value.

### 6.5 Curator controls

| Control | Effect | Why it is safe |
|---|---|---|
| `freezeInflow(i)` (curator or oracle trigger) | swaps with coin $i$ as **input** revert; $i$ as output is still allowed | it only shrinks the reachable set, so T4 still holds; buyers removing junk only help |
| `delist(i)` | after a freeze: pro-rata withdrawal only, then the pool is re-deployed without $i$ | there is no in-place re-centring of $K$, which would hand an instant arbitrage to whoever trades first |
| parameter change $(b_i, R)$ | allowed only as a linear ramp over $\ge \tau$ blocks, recomputing $K = F(\mathbf{x}; \text{params}_t)$ each block | an instant change moves prices discontinuously; a ramp bounds the per-block price change (same reasoning as Curve's $A$ ramp) |

Weights $w_i$ are immutable for the life of a pool. Changing them would move the
balanced state, which is a re-deployment.

---

## 7. Comparison with StableSwap (normative summary)

| Property | StableSwap | Balanced Fermi–Dirac |
|---|---|---|
| Invariant | not separable (sum and product coupled through $D$) | separable sum $\sum w_i f_i(x_i/w_i)$ |
| Unequal target at par | not expressible | built in (T1) |
| Swap solver | Newton on a quadratic (`get_y`) | closed form via $g$ |
| Loss from one failed coin | → TVL (no floor) | $\le w_h c_h + \varepsilon_0$ (T4) |
| Depth | most of TVL at a few bps | about $w_i V b_i$ per coin |

The figures behind the last two rows on the live 3pool state ($\$158.7$M: Curve
loses 100%, Fermi with $b = 30\%$ loses 43%) are in `curve-vs-fermi-depeg-drain.md`
§5.

---

## 8. Numerical implementation

### 8.1 Units

Every token amount is converted to a common 18-decimal unit before it touches the
curve, $x_i = \text{balance}_i \cdot \text{rate}_i$, in the same way as Curve's
`RATES`. For plain stablecoins $\text{rate}_i$ is a constant decimal adjustment.
Yield-bearing tokens need a rate provider and are out of scope for v0.1.

### 8.2 Stable evaluation

Never evaluate $e^{z}$ for $z > 0$. Use:

$$
\sigma(z) = \max(z, 0) + \ln\!\left(1 + e^{-|z|}\right)
$$

$$
\sigma^{-1}(a) = a + \ln\!\left(1 - e^{-a}\right), \qquad a > 0
$$

$$
f'(r) = \begin{cases} e^{-z}/(1+e^{-z}) & z > 0 \\ 1/(1+e^{z}) & z \le 0 \end{cases},
\qquad z = \frac{r - c}{T}
$$

Each $\exp$ then has a non-positive argument and returns a value in $(0, 1]$, so
fixed-point libraries (e.g. Solady `expWad` / `lnWad`) are never near overflow.
Underflow of $e^{-|z|}$ to 0 is harmless: it means the coin is deep in the linear
regime or deep past its wall, and in both cases the exact value differs from the
limit by less than one unit in the last place.

Precision hazard: for $a \to 0^+$ (coin far past its wall, $u \to 0^-$),
$\ln(1 - e^{-a})$ cancels catastrophically. Implementations must compute
$1 - e^{-a}$ as `-expm1(-a)` or an equivalent series for small $a$, or revert when
$a < a_{\min}$. $R_{\max}$ (§5.2) is chosen so that $T_i$ in wad units keeps at least
12 significant digits for the smallest $b_i$ in the pool.

### 8.3 Rounding

The pool never rounds in a trader's favour:

| Quantity | Direction |
|---|---|
| $\Delta_{\text{out}}$ (exact input) | down |
| $\Delta$ required (exact output) | up |
| fee | up |
| deposit amounts | up |
| withdrawal amounts | down |

Post-condition on every swap: $F(\mathbf{x}') \ge K - \eta$, where $\eta$ is a fixed
tolerance a few wei wide that covers the error of `ln`/`exp`. A conforming
implementation documents $\eta$ and fuzzes against it.

### 8.4 Domain guards (revert conditions)

| Condition | Meaning |
|---|---|
| $u \ge 0$ in §6.2 step 3 | exceeds capacity |
| $x_j' \le x_{\min}$ in §6.1 step 5 / §6.2 step 1 | the output coin would be drained (T6 not satisfied for $j$) |
| $\Delta_{\text{out}} = 0$ | the swap is entirely past the wall. Implementations may return 0 instead of reverting, but must not mint or transfer |
| `inflowFrozen[i]` | §6.5 |

### 8.5 Gas notes

`rest` changes only for the two coins a swap touches. An implementation can cache
$F_{\text{terms}}[k] = w_k f_k(r_k)$ per coin and update two entries per swap. That
makes a swap cost $O(1)$ in $n$: two `ln`, two `exp`, plus one `ln`/`exp` pair for
$g$.

---

## 9. Uniswap v4 hook mapping

v4 pools are two-token, but the basket is $n$-token. The hook is therefore a
**singleton basket** that owns the shared state $\Sigma$, and each of the
$\binom{n}{2}$ pairs is registered as a v4 pool whose curve is replaced by the basket.

| Hook permission | Use |
|---|---|
| `beforeInitialize` | bind the `PoolKey` to the basket; reject unknown currencies |
| `beforeAddLiquidity` / `beforeRemoveLiquidity` | revert. Native concentrated liquidity is disabled; LPs use the basket's §6.3 entry points |
| `beforeSwap` + `beforeSwapReturnDelta` | run §6.1 or §6.2 and return a `BeforeSwapDelta` that fully consumes the specified amount and supplies the unspecified one, so the PoolManager's built-in curve executes nothing (the custom-curve pattern) |

Inside `beforeSwap`, `zeroForOne` gives the direction $i \to j$, and the sign of
`amountSpecified` gives exact input or exact output (negative means exact input in
v4). Basket reserves are held as ERC-6909 claims in the PoolManager, so every pair
settles against the same balances without moving ERC-20s on each swap. The exact
delta signs and settlement calls must follow the v4-core version pinned in
`foundry.lock`.

Because all pairs read and write one $\Sigma$, an arbitrage loop across pairs inside
a single unlock is just a sequence of §6.1 calls on one invariant, and T3 makes it
unprofitable.

---

## 10. Security considerations

1. **The loss floor assumes the invariant is enforced exactly.** Any path that changes
   $\mathbf{x}$ without going through §6 voids T4: direct transfers counted as
   reserves, fee leakage into $\mathbf{x}$, or single-sided deposits priced at par.
   Reserves are internal accounting, so donations are ignored.
2. **Rounding drift.** If $\eta$ is too wide, repeated swaps could ratchet $F$ below
   $K$ and loosen T4 a little at a time. Fuzz the post-condition over long random
   paths (as in §12, Y8) at the fixed-point precision actually deployed.
3. **Oracle freeze.** `freezeInflow` is only as good as its trigger. A false trigger
   halts one direction of trade but cannot lose funds. A missed trigger leaves T4 as
   the backstop.
4. **Parameter ramps** are sandwichable within each step. Bound the per-block price
   change.
5. **Multiple correlated failures** (for example a coin collateralised by another
   coin in the basket) cost up to $\sum_S w_h c_h$. Curators should treat correlated
   coins as a single $S$ when setting $L_i$.
6. **Temporary depegs.** The floor stops arbitrageurs from buying the good coins
   cheaply. If the coin later re-pegs, LPs who stayed in Curve would have recovered
   too. The protection is designed for permanent failures.

---

## 11. Known limits (non-goals for v0.1)

- Depth is capped at about $w_i V b_i$ of one-way flow per coin. Large directional
  flow is refused, together with its fees.
- There is no in-place re-centring after a failure; delisting means re-deployment.
- Yield-bearing tokens, dynamic weights and single-sided liquidity are not specified.

---

## 12. Test vectors

Pool: USDC / USDT / NEW, $\mathbf{x}^0 = (100, 50, 10)$, $V = 160$,
$\mathbf{w} = (0.625, 0.3125, 0.0625)$, $\mathbf{b} = (0.40, 0.40, 0.10)$, $R = 10$,
no fees. Reproduce with `python3 tools/yellowpaper_vectors.py`.

### Y1 — Parameters and constants

| Coin | $c_i$ | $T_i$ | Wall $w_i c_i$ | Room |
|---|---|---|---|---|
| USDC | $224.0$ | $6.40$ | $140.00$ | $40.00$ |
| USDT | $224.0$ | $6.40$ | $70.00$ | $20.00$ |
| NEW | $176.0$ | $1.60$ | $11.00$ | $1.00$ |

| Constant | Value |
|---|---|
| $K$ (direct) | $-61.00027693$ |
| $K$ (closed form §3.3) | $-61.00027693$ |
| $\varphi$ | $0.9999546021$ |
| $\varepsilon_0$ | $0.00027693$ |
| $C$ | $159.99972307$ |

### Y2 — Balanced form

$\sum x_i - \sum \varepsilon_i = 159.99972307 = C$ ✓

### Y3 — Swaps

| Call | Result |
|---|---|
| exact-in: 5 USDC → USDT | $4.999631$ out |
| exact-out: that output, USDC needed | $5.000000$ (round trip) |
| exact-out: 5 USDT, USDC needed | $5.000369$ |
| $\text{cap}_{\text{USDC}\to\text{USDT}}$ | $40.000272$ |
| $\text{cap}_{\text{USDT}\to\text{USDC}}$ | $20.000271$ |
| $\text{cap}_{\text{NEW}\to\text{USDC}}$ | $1.000045$ |
| exact-out: 1.5 USDC for NEW | **revert**, exceeds capacity |

T2 check on the first row: the bound gives
$\frac{4}{5}\, e^{(168 - 224)/6.4} = 1.27$ bps; the actual slippage is $0.74$ bps.

### Y4 — Homogeneity

| $\lambda$ | $K(\lambda)$ | $\lambda K$ | spot USDC→USDT |
|---|---|---|---|
| $2$ | $-122.00055387$ | $-122.00055387$ | $1.0000000000$ |
| $10$ | $-610.00276933$ | $-610.00276933$ | $1.0000000000$ |
| $0.001$ | $-0.06100028$ | $-0.06100028$ | $1.0000000000$ |

### Y5 — Proportional deposit (from an off-target state, $\delta = 25\%$)

The pool first takes 5 USDC → USDT. After the deposit, $F = -76.25034617 = 1.25K$.
Spots before and after are identical: USDC→USDT $0.9998452905$, NEW→USDC
$1.0001130563$.

### Y6 — Hack each coin to \$0 (greedy dump)

| Hacked | Paid out | Room | Good left | T4 bound | Total loss | $w_h c_h + \varepsilon_0$ |
|---|---|---|---|---|---|---|
| USDC | $40.000277$ | $40.00$ | $19.999723$ | $19.999723$ | $140.000277$ | $140.000277$ |
| USDT | $20.000276$ | $20.00$ | $89.999724$ | $89.999723$ | $70.000276$ | $70.000277$ |
| NEW | $1.000046$ | $1.00$ | $148.999954$ | $148.999723$ | $11.000046$ | $11.000277$ |

Losses as a share of TVL: 87.5% / 43.75% / 6.88%. Curve loses 100% in every row
(`fermi-from-scratch.md` §8.2).

### Y7 — No-drain condition (T6)

| Coin | $w_j$ | $\sum_{k\ne j} w_k b_k$ | Status |
|---|---|---|---|
| USDC | $0.6250$ | $0.1313$ | guaranteed |
| USDT | $0.3125$ | $0.2562$ | guaranteed |
| NEW | $0.0625$ | $0.3750$ | **not guaranteed**: the §8.4 revert is reachable if USDC and USDT are both dumped past their walls |

### Y8 — Fuzz

300 random pools ($R \in \{10, 30, 100\}$), 60 random swaps each: 16,112 executed and
1,888 reverted by the §8.4 guards.

| Check | Worst case |
|---|---|
| $\lvert F - K\rvert$ after any swap | $2.8 \times 10^{-14}$ |
| T4 margin over every state and every single $h$ | $-2.8 \times 10^{-14}$ (float rounding; the theorem is strict) |

### Y9 — Ratio mismatch (why $R$ is pool-level)

One coin at $R = 3$ and the rest at $R = 10$ gives $p = 0.952617$ at rest, 474 bps off
peg.

---

## Appendix A — Derivation pointers

| Result | Derived in |
|---|---|
| $\sum f(x_i)$ as the general separable AMM; constant sum and product as special cases | `fermi-dirac-derivation.md` §5.0 |
| Choosing $f'$ as Fermi–Dirac occupancy and integrating to $f$, $g$ | `fermi-dirac-derivation.md` §5.2–5.3 |
| Weight normalisation and the cancellation of the outer $w_i$ | `weighted-fermi.md` §2 |
| Why StableSwap cannot be weighted | `weighted-fermi.md` §6 |
| Loss-cap parameterisation $L_i \to b_i$ | `weighted-fermi.md` §9 |
| Live 3pool comparison and attack model | `curve-vs-fermi-depeg-drain.md` |
| Dollar savings and break-even probability | `fermi-vs-curve-savings.md` |

## Appendix B — Changes from the earlier notes

- $T_i$ is defined as $V b_i / R$ with a single pool-level $R$, rather than "ratio 10"
  by convention. This makes the T1 peg condition structural.
- $c_i$ and $T_i$ scale with $V$, which makes the invariant 1-homogeneous (§3.4) and
  defines proportional liquidity exactly. The earlier notes left deposits open.
- The loss cap is proved as a path-independent inequality (T4) rather than a limit
  argument, with the exact correction $\varepsilon_0$.
- New: exact-output swaps, the capacity formula (T5), the no-drain condition (T6),
  fee segregation (§6.4) and the curator controls (§6.5).
