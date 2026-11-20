import { capacityDetail, invariant, phi, spot, type PoolState } from '../lib/fermi'
import { bps, fmt, fmtAmt } from '../lib/format'
import { PRESETS, type Preset } from '../lib/presets'
import { Basket } from './Basket'
import { ResetIcon } from './icons'
import { OccupancyChart } from './OccupancyChart'
import type { Trade } from './SwapCard'

interface Props {
  preset: Preset
  pool: PoolState
  trades: Trade[]
  focus: number
  onFocus: (i: number) => void
  onPreset: (id: string) => void
  onReset: () => void
}

export function Dashboard({ preset, pool, trades, focus, onFocus, onPreset, onReset }: Props) {
  const { params: p, V, x, K } = pool
  const unit = preset.unit
  const n = p.symbols.length
  const tvl = x.reduce((a, b) => a + b, 0)
  const drift = Math.abs(invariant(p, V, x) - K)
  const volume = trades.reduce((a, t) => a + t.amountIn, 0)
  // largest deviation from par across all pairs
  let worst = 0
  for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) worst = Math.max(worst, Math.abs(1 - spot(pool, i, j)))

  const pairs: [number, number][] = []
  for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) pairs.push([i, j])

  return (
    <>
      <div className="page-head">
        <div>
          <p className="eyebrow">Uniswap v4 hook · multi-stablecoin basket</p>
          <h1>Pool dashboard</h1>
          <p className="muted">{preset.note}</p>
        </div>
        <div className="page-actions">
          <label className="select-wrap plain">
            <span className="sr-only">Pool</span>
            <select value={preset.id} onChange={(e) => onPreset(e.target.value)}>
              {PRESETS.map((pr) => (
                <option key={pr.id} value={pr.id}>
                  {pr.name}
                </option>
              ))}
            </select>
          </label>
          <button className="ghost" onClick={onReset}>
            <ResetIcon /> Reset
          </button>
        </div>
      </div>

      <dl className="stats">
        <Stat label="TVL" value={fmtAmt(tvl, unit, 2)} sub={`${n} coins · V = ${fmtAmt(V, unit, 1)}`} />
        <Stat label="Max deviation from par" value={bps(worst)} sub="across all pairs, at spot" />
        <Stat label="Sharpness R" value={p.R.toFixed(0)} sub={`at rest: ${bps(1 - phi(p.R))} off par`} />
        <Stat label="Invariant drift |F − K|" value={drift.toExponential(1)} sub={`K = ${fmt(K, 4)}`} />
        <Stat
          label="Session volume"
          value={fmtAmt(volume, unit, 2)}
          sub={`${trades.length} trade${trades.length === 1 ? '' : 's'}`}
        />
      </dl>

      <div className="grid-dash">
        <Basket pool={pool} preview={null} unit={unit} focus={focus} onFocus={onFocus} />
        <section className="card" aria-labelledby="occ-h">
          <header className="card-head">
            <h3 id="occ-h">Occupancy curve</h3>
            <div className="seg small" role="tablist" aria-label="Coin">
              {p.symbols.map((s, i) => (
                <button
                  key={s}
                  role="tab"
                  aria-selected={focus === i}
                  className={focus === i ? 'on' : ''}
                  onClick={() => onFocus(i)}
                >
                  {s}
                </button>
              ))}
            </div>
          </header>
          <OccupancyChart pool={pool} coin={focus} preview={null} unit={unit} />
        </section>
      </div>

      <div className="grid-dash">
        <section className="card" aria-labelledby="pairs-h">
          <header className="card-head">
            <h3 id="pairs-h">Pairs</h3>
            <span className="muted small">each pair is a v4 pool on the shared basket</span>
          </header>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th scope="col">Pair</th>
                  <th scope="col">Spot</th>
                  <th scope="col">Capacity →</th>
                  <th scope="col">Capacity ←</th>
                </tr>
              </thead>
              <tbody>
                {pairs.map(([i, j]) => (
                  <tr key={`${i}-${j}`}>
                    <th scope="row">
                      <i className="swatch" style={{ background: `var(--c${i % 5})` }} />
                      {p.symbols[i]}
                      <span className="muted"> / </span>
                      <i className="swatch" style={{ background: `var(--c${j % 5})` }} />
                      {p.symbols[j]}
                    </th>
                    <td className="mono">{spot(pool, i, j).toFixed(6)}</td>
                    <Cap pool={pool} i={i} j={j} unit={unit} />
                    <Cap pool={pool} i={j} j={i} unit={unit} />
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="muted small table-note">
            Capacity is the most that can ever come out of the pair, whatever the input size (T5).{' '}
            <span className="accent">all</span> means the formula reaches the whole reserve: T6 doesn't hold for that
            coin, and the drain guard (§8.4) reverts instead.
          </p>
        </section>

        <section className="card" aria-labelledby="trades-h">
          <header className="card-head">
            <h3 id="trades-h">Recent trades</h3>
            <a className="link" href="#/swap">
              new swap
            </a>
          </header>
          {trades.length === 0 ? (
            <p className="muted small empty">
              No trades yet. Open <a href="#/swap">Swap</a> and try pushing a coin past its wall.
            </p>
          ) : (
            <ol className="trades">
              {trades.map((t) => (
                <li key={t.id}>
                  <span className="mono">
                    {fmtAmt(t.amountIn, unit)} {t.from}
                  </span>
                  <span className="muted">→</span>
                  <span className="mono">
                    {fmtAmt(t.amountOut, unit)} {t.to}
                  </span>
                  <span className="muted small trade-rate mono">{bps(1 - t.amountOut / t.amountIn, 1)}</span>
                </li>
              ))}
            </ol>
          )}
        </section>
      </div>
    </>
  )
}

function Cap({ pool, i, j, unit }: { pool: PoolState; i: number; j: number; unit: Preset['unit'] }) {
  const c = capacityDetail(pool, i, j)
  return (
    <td className="mono">
      {fmtAmt(c.amount, unit, 2)} <span className="muted">{pool.params.symbols[j]}</span>
      {c.drainable && <span className="accent small"> all</span>}
    </td>
  )
}

function Stat({ label, value, sub }: { label: string; value: string; sub: string }) {
  return (
    <div className="stat">
      <dt>{label}</dt>
      <dd className="mono">{value}</dd>
      <dd className="muted small">{sub}</dd>
    </div>
  )
}
