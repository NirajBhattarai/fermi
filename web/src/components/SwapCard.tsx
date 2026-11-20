import { useEffect, useMemo, useRef, useState } from 'react'
import { capacity, quoteExactIn, quoteExactOut, room, spot, SwapRevert, type PoolState } from '../lib/fermi'
import { bps, cleanDecimal, fmt, fmtAmt, parseAmount } from '../lib/format'
import type { Unit } from '../lib/presets'
import { AlertIcon, CheckIcon, SwapIcon } from './icons'

export interface Trade {
  id: number
  from: string
  to: string
  amountIn: number
  amountOut: number
}

interface Props {
  pool: PoolState
  unit: Unit
  onPreview: (x: number[] | null) => void
  onExecute: (x: number[], trade: Omit<Trade, 'id'>) => void
  onFocusCoin: (i: number) => void
}

type Quote =
  | { ok: true; amountIn: number; amountOut: number; x: number[] }
  | { ok: false; error: string; reason: SwapRevert['reason'] }

export function SwapCard({ pool, unit, onPreview, onExecute, onFocusCoin }: Props) {
  const n = pool.params.symbols.length
  const [from, setFrom] = useState(0)
  const [to, setTo] = useState(1)
  const [mode, setMode] = useState<'in' | 'out'>('in')
  const [value, setValue] = useState('5')
  const [turns, setTurns] = useState(0)
  const [done, setDone] = useState(false)
  const doneTimer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(doneTimer.current), [])

  const i = Math.min(from, n - 1)
  const j = Math.min(to, n - 1) === i ? (i + 1) % n : Math.min(to, n - 1)
  const sym = pool.params.symbols

  const amount = parseAmount(value)
  const quote: Quote = useMemo(() => {
    try {
      if (mode === 'in') {
        const q = quoteExactIn(pool, i, j, amount)
        return { ok: true, amountIn: amount, amountOut: q.amountOut, x: q.x }
      }
      const q = quoteExactOut(pool, i, j, amount)
      return { ok: true, amountIn: q.amountIn, amountOut: amount, x: q.x }
    } catch (e) {
      if (e instanceof SwapRevert) return { ok: false, error: e.message, reason: e.reason }
      throw e
    }
  }, [pool, i, j, amount, mode])

  useEffect(() => {
    onPreview(quote.ok ? quote.x : null)
  }, [quote, onPreview])

  const spotPx = spot(pool, i, j)
  const cap = capacity(pool, i, j)
  const fill = quote.ok ? quote.amountOut / quote.amountIn : NaN
  const impact = quote.ok ? 1 - fill / spotPx : NaN
  const roomAfter = quote.ok ? room(pool, i) - (quote.x[i] - pool.x[i]) : NaN
  const pastWall = quote.ok && roomAfter < 0

  const shown = (side: 'in' | 'out') => {
    if (side === mode) return value
    if (!quote.ok) return ''
    return fmt(side === 'in' ? quote.amountIn : quote.amountOut, 6).replace(/,/g, '')
  }

  const flip = () => {
    setTurns((t) => t + 1)
    setDone(false)
    setFrom(j)
    setTo(i)
    setMode(mode === 'in' ? 'out' : 'in')
    if (quote.ok) setValue(String(+(mode === 'in' ? quote.amountOut : quote.amountIn).toFixed(6)))
  }

  const pick = (side: 'from' | 'to', k: number) => {
    if (side === 'from') {
      if (k === j) setTo(i)
      setFrom(k)
    } else {
      if (k === i) setFrom(j)
      setTo(k)
    }
    onFocusCoin(side === 'from' ? k : i)
  }

  const execute = () => {
    if (!quote.ok) return
    onExecute(quote.x, { from: sym[i], to: sym[j], amountIn: quote.amountIn, amountOut: quote.amountOut })
    setDone(true)
    window.clearTimeout(doneTimer.current)
    doneTimer.current = window.setTimeout(() => setDone(false), 1400)
  }

  const buttonLabel = quote.ok
    ? `Swap ${sym[i]} → ${sym[j]}`
    : quote.reason === 'input'
      ? 'Enter an amount'
      : quote.reason === 'capacity'
        ? 'Exceeds pair capacity'
        : 'Swap would revert'

  return (
    <section className="card swap" aria-labelledby="swap-h">
      <header className="card-head">
        <h3 id="swap-h">Swap</h3>
        <span className="chip">exact {mode === 'in' ? 'input' : 'output'}</span>
      </header>

      <TokenField
        label="You pay"
        symbols={sym}
        selected={i}
        onSelect={(k) => pick('from', k)}
        value={shown('in')}
        onChange={(v) => {
          setMode('in')
          setDone(false)
          setValue(v)
        }}
      />

      <button className="flip" onClick={flip} aria-label="Reverse swap direction">
        <SwapIcon style={{ transform: `rotate(${turns * 180}deg)` }} />
      </button>

      <TokenField
        label="You receive"
        symbols={sym}
        selected={j}
        onSelect={(k) => pick('to', k)}
        value={shown('out')}
        onChange={(v) => {
          setMode('out')
          setDone(false)
          setValue(v)
        }}
        hint={
          <button
            className="link"
            onClick={() => {
              setMode('out')
              setValue(String(+(cap * 0.999).toFixed(6)))
            }}
          >
            capacity {fmtAmt(cap, unit)}
          </button>
        }
      />

      <dl className="quote">
        <div>
          <dt>Spot</dt>
          <dd className="mono">
            1 {sym[i]} = {spotPx.toFixed(6)} {sym[j]}
          </dd>
        </div>
        <div>
          <dt>Price impact</dt>
          <dd className={`mono ${quote.ok && impact > 0.005 ? 'bad' : ''}`}>{quote.ok ? bps(impact) : '—'}</dd>
        </div>
        <div>
          <dt>{sym[i]} room after</dt>
          <dd className={`mono ${pastWall ? 'accent' : ''}`}>
            {quote.ok ? (pastWall ? `past wall by ${fmtAmt(-roomAfter, unit)}` : fmtAmt(roomAfter, unit)) : '—'}
          </dd>
        </div>
      </dl>

      {!quote.ok && quote.reason !== 'input' && (
        <p className="notice bad" role="status">
          <AlertIcon />
          <span>
            {quote.error}.{' '}
            {quote.reason === 'capacity' &&
              `No finite amount of ${sym[i]} buys more than ${fmtAmt(cap, unit)} ${sym[j]} (T5).`}
          </span>
        </p>
      )}
      {pastWall && (
        <p className="notice accent" role="status">
          <AlertIcon />
          <span>
            This trade pushes {sym[i]} past its wall, where each extra unit is worth half or less. That is the mechanism
            that caps LP loss.
          </span>
        </p>
      )}

      <button className="primary" disabled={!quote.ok} onClick={execute}>
        {done ? (
          <span className="btn-done">
            <CheckIcon /> Swapped
          </span>
        ) : (
          buttonLabel
        )}
      </button>
      <p className="fine">Runs the §6.1 / §6.2 transitions locally. No wallet, no chain.</p>
    </section>
  )
}

interface FieldProps {
  label: string
  symbols: string[]
  selected: number
  onSelect: (k: number) => void
  value: string
  onChange: (v: string) => void
  hint?: React.ReactNode
}

function TokenField({ label, symbols, selected, onSelect, value, onChange, hint }: FieldProps) {
  const id = `f-${label.replace(/\s/g, '')}`
  return (
    <div className="token-field">
      <div className="token-field-top">
        <label htmlFor={id}>{label}</label>
        {hint}
      </div>
      <div className="token-field-row">
        <input
          id={id}
          className="amount"
          inputMode="decimal"
          autoComplete="off"
          placeholder="0.0"
          value={value}
          onChange={(e) => onChange(cleanDecimal(e.target.value))}
        />
        <div className="select-wrap">
          <i className="swatch" style={{ background: `var(--c${selected % 5})` }} />
          <select value={selected} onChange={(e) => onSelect(Number(e.target.value))} aria-label={`${label} token`}>
            {symbols.map((s, k) => (
              <option key={s} value={k}>
                {s}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  )
}
