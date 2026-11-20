/**
 * Balanced Fermi–Dirac invariant, as specified in docs/yellow-paper.md.
 *
 *   F(x; V) = Σ w_i f_i(x_i / w_i) = K
 *   f_i(r)  = -T_i σ((c_i - r) / T_i),  c_i = V(1 + b_i),  T_i = V b_i / R
 *
 * Float64 reference implementation for the UI. Every exp() has a
 * non-positive argument (§8.2), so nothing overflows.
 */

export interface PoolParams {
  symbols: string[]
  /** target weights, Σ w = 1 */
  w: number[]
  /** budgets: how far past target each coin may go at ~par, as a fraction of V */
  b: number[]
  /** pool-level sharpness ratio */
  R: number
}

export interface PoolState {
  params: PoolParams
  /** curve reserves, common units */
  x: number[]
  /** pool scale (total reserves at the balanced state) */
  V: number
  /** invariant level */
  K: number
}

export class SwapRevert extends Error {
  reason: 'capacity' | 'drain' | 'zero' | 'input'
  constructor(reason: SwapRevert['reason'], message: string) {
    super(message)
    this.reason = reason
  }
}

const X_MIN = 1e-12

/** softplus σ(z) = ln(1 + e^z), stable */
export const softplus = (z: number) => Math.max(z, 0) + Math.log1p(Math.exp(-Math.abs(z)))

/** σ⁻¹(a) = a + ln(1 − e^{−a}), a > 0, with expm1 against cancellation */
export const softplusInv = (a: number) => a + Math.log(-Math.expm1(-a))

export const cap = (p: PoolParams, V: number, i: number) => V * (1 + p.b[i])
export const temp = (p: PoolParams, V: number, i: number) => (V * p.b[i]) / p.R

/** f_i(r) */
export function f(p: PoolParams, V: number, i: number, r: number) {
  const c = cap(p, V, i)
  const T = temp(p, V, i)
  return -T * softplus((c - r) / T)
}

/** f_i'(r): Fermi–Dirac occupancy, strictly in (0, 1) */
export function fPrime(p: PoolParams, V: number, i: number, r: number) {
  const z = (r - cap(p, V, i)) / temp(p, V, i)
  if (z > 0) {
    const e = Math.exp(-z)
    return e / (1 + e)
  }
  return 1 / (1 + Math.exp(z))
}

/** g_i(u) = f_i⁻¹(u), u < 0 */
export function g(p: PoolParams, V: number, i: number, u: number) {
  const T = temp(p, V, i)
  return cap(p, V, i) - T * softplusInv(-u / T)
}

/** term_i = w_i f_i(x_i / w_i) */
const term = (p: PoolParams, V: number, i: number, xi: number) => p.w[i] * f(p, V, i, xi / p.w[i])

export function invariant(p: PoolParams, V: number, x: number[]) {
  return x.reduce((s, xi, i) => s + term(p, V, i, xi), 0)
}

/** φ = (1 + e^{−R})⁻¹, slope of every f_i at the balanced state */
export const phi = (R: number) => 1 / (1 + Math.exp(-R))

/** Closed form K = −σ(R)/R · V Σ w_i b_i (§3.3) */
export const closedFormK = (p: PoolParams, V: number) =>
  (-softplus(p.R) / p.R) * V * p.w.reduce((s, wi, i) => s + wi * p.b[i], 0)

/** ε₀ = σ(−R)/R · V Σ w_i b_i */
export const epsilon0 = (p: PoolParams, V: number) =>
  (softplus(-p.R) / p.R) * V * p.w.reduce((s, wi, i) => s + wi * p.b[i], 0)

export function createPool(params: PoolParams, V: number): PoolState {
  const x = params.w.map((wi) => wi * V)
  return { params, x, V, K: invariant(params, V, x) }
}

const rest = (s: PoolState, skip: number[]) =>
  s.x.reduce((acc, xi, k) => (skip.includes(k) ? acc : acc + term(s.params, s.V, k, xi)), 0)

/** Spot price of coin i in units of coin j (T1) */
export function spot(s: PoolState, i: number, j: number) {
  const { params: p, V, x } = s
  return fPrime(p, V, i, x[i] / p.w[i]) / fPrime(p, V, j, x[j] / p.w[j])
}

/** §6.1 exact-input swap. Returns amount of j out and the new reserves. */
export function quoteExactIn(s: PoolState, i: number, j: number, amountIn: number) {
  if (i === j || !(amountIn > 0)) throw new SwapRevert('input', 'Enter an amount')
  const { params: p, V, K, x } = s
  const xi2 = x[i] + amountIn
  const u = (K - rest(s, [i, j]) - term(p, V, i, xi2)) / p.w[j]
  const xj2 = p.w[j] * g(p, V, j, u)
  if (!(xj2 > X_MIN)) throw new SwapRevert('drain', `Would drain ${p.symbols[j]}`)
  const out = x[j] - xj2
  if (!(out > 0)) throw new SwapRevert('zero', 'Swap is entirely past the wall')
  const next = x.slice()
  next[i] = xi2
  next[j] = xj2
  return { amountOut: out, x: next }
}

/** §6.2 exact-output swap. Returns amount of i required. */
export function quoteExactOut(s: PoolState, i: number, j: number, amountOut: number) {
  if (i === j || !(amountOut > 0)) throw new SwapRevert('input', 'Enter an amount')
  const { params: p, V, K, x } = s
  const xj2 = x[j] - amountOut
  if (!(xj2 > X_MIN)) throw new SwapRevert('drain', `Would drain ${p.symbols[j]}`)
  const u = (K - rest(s, [i, j]) - term(p, V, j, xj2)) / p.w[i]
  if (u >= 0) throw new SwapRevert('capacity', 'Exceeds pool capacity for this pair')
  const xi2 = p.w[i] * g(p, V, i, u)
  const next = x.slice()
  next[i] = xi2
  next[j] = xj2
  return { amountIn: xi2 - x[i], x: next }
}

/**
 * T5: supremum of output for i → j over all input sizes, capped at the
 * reserve of j. `drainable` is true when the formula reaches past x_j, i.e.
 * T6 fails for j along this pair and the §8.4 drain guard is what binds.
 */
export function capacityDetail(s: PoolState, i: number, j: number) {
  const { params: p, V, K, x } = s
  const u = (K - rest(s, [i, j])) / p.w[j]
  const raw = x[j] - p.w[j] * g(p, V, j, u)
  return raw >= x[j] ? { amount: x[j], drainable: true } : { amount: raw, drainable: false }
}

export const capacity = (s: PoolState, i: number, j: number) => capacityDetail(s, i, j).amount

/** Room of coin i: how much more of it the pool absorbs before its wall */
export const room = (s: PoolState, i: number) => s.params.w[i] * cap(s.params, s.V, i) - s.x[i]

/** Wall in absolute reserve units: w_i c_i */
export const wall = (p: PoolParams, V: number, i: number) => p.w[i] * cap(p, V, i)

/**
 * Hack coin h: an attacker mints `dump` of it and takes the best possible
 * mix of good coins. By path independence the result is the minimum of
 * Σ_{k≠h} x_k on the level set with x_h fixed, reached where every good coin
 * has the same marginal value (strict concavity, T3). Solved by bisection on
 * the shared reduced coordinate z = (r_k − c_k)/T_k.
 */
export function hack(s: PoolState, h: number, dump: number) {
  const { params: p, V, K, x } = s
  const n = x.length
  const xh = x[h] + dump
  const target = K - term(p, V, h, xh)
  const good = [...Array(n).keys()].filter((k) => k !== h)

  const goodAt = (z: number) => good.map((k) => Math.max(p.w[k] * (cap(p, V, k) + temp(p, V, k) * z), X_MIN))
  const sumTerms = (xs: number[]) => xs.reduce((acc, xk, idx) => acc + term(p, V, good[idx], xk), 0)

  let lo = -1e4
  let hi = 1e4
  for (let it = 0; it < 200; it++) {
    const mid = (lo + hi) / 2
    if (sumTerms(goodAt(mid)) < target) lo = mid
    else hi = mid
  }
  const xs = goodAt(hi)
  const goodLeft = xs.reduce((a, b) => a + b, 0)
  const goodBefore = good.reduce((acc, k) => acc + x[k], 0)
  const totalBefore = x.reduce((a, b) => a + b, 0)
  return {
    /** good coins handed to the attacker */
    paidOut: goodBefore - goodLeft,
    goodLeft,
    /** LP loss with coin h valued at 0, vs. pool value before the hack */
    loss: totalBefore - goodLeft,
    lossPct: (totalBefore - goodLeft) / totalBefore,
    reserves: good.map((k, idx) => ({ k, x: xs[idx] })),
  }
}

/** T4 single-failure bound: w_h c_h + ε₀ */
export const lossBound = (s: PoolState, h: number) => wall(s.params, s.V, h) + epsilon0(s.params, s.V)

/** T6: coin j can never be drained if w_j − Σ_{k≠j} w_k b_k > ε₀/V */
export function noDrain(p: PoolParams, V: number, j: number) {
  const others = p.w.reduce((acc, wk, k) => (k === j ? acc : acc + wk * p.b[k]), 0)
  return { margin: p.w[j] - others, others, ok: p.w[j] - others > epsilon0(p, V) / V }
}
