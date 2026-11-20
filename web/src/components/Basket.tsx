import { fPrime, invariant, phi, room, wall, type PoolState } from '../lib/fermi'
import { fmtAmt, pct } from '../lib/format'
import type { Unit } from '../lib/presets'

interface Props {
  pool: PoolState
  preview: number[] | null
  unit: Unit
  focus: number
  onFocus: (i: number) => void
}

export function Basket({ pool, preview, unit, focus, onFocus }: Props) {
  const { params: p, V, x, K } = pool
  const walls = p.symbols.map((_, i) => wall(p, V, i))
  const scale = Math.max(...walls.map((w, i) => Math.max(w * 1.12, x[i] * 1.04, (preview?.[i] ?? 0) * 1.04)))
  const tvl = x.reduce((a, b) => a + b, 0)
  const drift = invariant(p, V, x) - K
  const ph = phi(p.R)

  return (
    <section className="card basket" aria-labelledby="basket-h">
      <header className="card-head">
        <h3 id="basket-h">Basket</h3>
        <span className="muted small">
          TVL <b className="mono">{fmtAmt(tvl, unit, 2)}</b>
        </span>
      </header>

      <ul className="coins">
        {p.symbols.map((s, i) => {
          const xi = x[i]
          const nx = preview?.[i]
          const changed = nx !== undefined && Math.abs(nx - xi) > 1e-12
          const target = p.w[i] * V
          const value = fPrime(p, V, i, xi / p.w[i]) / ph
          const rm = room(pool, i)
          const color = `var(--c${i % 5})`
          return (
            <li key={s}>
              <button
                className={`coin ${focus === i ? 'on' : ''}`}
                onClick={() => onFocus(i)}
                aria-pressed={focus === i}
                aria-label={`${s}: reserve ${fmtAmt(xi, unit)}, ${rm >= 0 ? 'room' : 'past wall by'} ${fmtAmt(Math.abs(rm), unit)}. Show on chart.`}
              >
                <div className="coin-top">
                  <span className="coin-sym">
                    <i className="swatch" style={{ background: color }} />
                    {s}
                    <span className="muted small">{pct(p.w[i], 1)}</span>
                  </span>
                  <span className="mono">
                    {fmtAmt(xi, unit)}
                    {changed && (
                      <span className={nx! > xi ? 'delta up' : 'delta down'}>
                        {nx! > xi ? ' +' : ' −'}
                        {fmtAmt(Math.abs(nx! - xi), unit)}
                      </span>
                    )}
                  </span>
                </div>

                <div className="track" aria-hidden>
                  <div className="track-clip">
                    <div className="track-past" style={{ left: `${(walls[i] / scale) * 100}%` }} />
                    <div
                      className="track-fill"
                      style={{ transform: `scaleX(${Math.min(xi / scale, 1)})`, background: color }}
                    />
                  </div>
                  {changed && (
                    <div
                      className="track-ghost"
                      style={{
                        left: `${(Math.min(xi, nx!) / scale) * 100}%`,
                        width: `${(Math.abs(nx! - xi) / scale) * 100}%`,
                        borderColor: color,
                      }}
                    />
                  )}
                  <div className="track-tick" style={{ left: `${(target / scale) * 100}%` }} />
                  <div className="track-tick wall" style={{ left: `${(walls[i] / scale) * 100}%` }} />
                </div>

                <div className="coin-meta small">
                  <span>
                    value <b className="mono">{value.toFixed(4)}×</b>
                  </span>
                  <span className={rm < 0 ? 'accent' : ''}>
                    {rm >= 0 ? 'room' : 'past wall'} <b className="mono">{fmtAmt(Math.abs(rm), unit)}</b>
                  </span>
                </div>
              </button>
            </li>
          )
        })}
      </ul>

      <div className="legend small muted">
        <span>
          <i className="tick-glyph" /> target
        </span>
        <span>
          <i className="tick-glyph wall" /> wall w·c
        </span>
        <span>
          |F − K| <b className="mono">{Math.abs(drift).toExponential(1)}</b>
        </span>
      </div>
    </section>
  )
}
