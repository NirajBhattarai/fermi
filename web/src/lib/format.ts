import type { Unit } from './presets'

export function fmt(n: number, dp = 2) {
  if (!Number.isFinite(n)) return '—'
  if (Math.abs(n) >= 1e6) {
    return n.toLocaleString('en-US', { notation: 'compact', maximumFractionDigits: 2 })
  }
  return n.toLocaleString('en-US', { minimumFractionDigits: dp, maximumFractionDigits: dp })
}

export const fmtAmt = (n: number, unit: Unit, dp = unit.dp) => `${unit.prefix}${fmt(n, dp)}${unit.suffix}`

export const pct = (x: number, dp = 2) => `${fmt(x * 100, dp)}%`

export const bps = (x: number, dp = 2) => `${fmt(x * 1e4, dp)} bps`

/** Parse a user-typed decimal; returns NaN for empty/invalid */
export function parseAmount(s: string) {
  const t = s.replace(/,/g, '').trim()
  if (t === '' || t === '.') return NaN
  return Number(t)
}

export const cleanDecimal = (s: string) => {
  const t = s.replace(/[^0-9.]/g, '')
  const i = t.indexOf('.')
  return i === -1 ? t : t.slice(0, i + 1) + t.slice(i + 1).replace(/\./g, '')
}
