import { useMemo, useState } from 'react'
import { createPool, hack, lossBound } from '../lib/fermi'
import { pct } from '../lib/format'
import { PAPER_SRC, REPO } from '../lib/links'
import { PRESETS } from '../lib/presets'
import { AlertIcon, ArrowUpRight, CheckIcon } from './icons'
import { OccupancyChart } from './OccupancyChart'

const scrollTo = (id: string) => {
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  document.getElementById(id)?.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' })
}

type Status = 'done' | 'pending' | 'no'

const VERIFY: { label: string; value: string; status: Status; href?: string }[] = [
  { label: 'Yellow paper', value: 'Draft v0.1, 2026-11-19', status: 'done', href: '#/paper' },
  {
    label: 'Test vectors (§12)',
    value: 'Y1–Y7 reproduced by this app',
    status: 'done',
    href: `${REPO}/blob/main/tools/yellowpaper_vectors.py`,
  },
  {
    label: 'Fuzz (Y8)',
    value: '300 pools · 16,112 swaps · |F − K| ≤ 2.8e-14',
    status: 'done',
    href: `${REPO}/blob/main/tools/yellowpaper_vectors.py`,
  },
  { label: 'Hook contract', value: 'In progress', status: 'pending', href: `${REPO}/tree/main/contracts` },
  { label: 'Deployed', value: 'No, not on any network', status: 'no' },
  { label: 'Audit', value: 'Not yet', status: 'no' },
  { label: 'UF Hook Security Framework self-score', value: 'Pending', status: 'pending' },
]

const COMPARE: { row: string; cells: [string, string, string, string]; strong?: boolean }[] = [
  { row: 'Assets per pool', cells: ['n-coin basket', 'n coins', '2', '2'] },
  {
    row: 'Near the peg',
    cells: [
      'near constant-sum below each wall',
      'amplified invariant',
      'fixed spread, dynamic fee',
      'concentrated x·y = k',
    ],
  },
  { row: 'Unequal target mix at 1:1', cells: ['yes (T1)', 'not expressible', 'n/a', 'n/a'] },
  {
    row: 'When one coin fails',
    cells: [
      'loss ≤ w·(1 + b) of the pool (T4)',
      'no floor: loss keeps growing toward the whole pool as the dump grows',
      'no stated bound',
      'no stated bound',
    ],
    strong: true,
  },
  { row: 'Swap solver', cells: ['closed form', 'Newton iteration', '—', '—'] },
  { row: 'Status', cells: ['research prototype', 'live', 'live, Sep 2026', 'live'] },
]

export function Overview() {
  const preset = PRESETS.find((p) => p.id === '3pool')!
  const paper = PRESETS.find((p) => p.id === 'paper')!
  const [presetId, setPresetId] = useState<'3pool' | 'paper'>('3pool')
  const pr = presetId === '3pool' ? preset : paper
  const pool = useMemo(() => createPool(pr.params, pr.V), [pr])
  const [coin, setCoin] = useState(0)
  const h = Math.min(coin, pr.params.symbols.length - 1)
  const result = useMemo(() => hack(pool, h, pool.V * 1e4), [pool, h])
  const floor = lossBound(pool, h) / pool.V
  const howPool = useMemo(() => createPool(paper.params, paper.V), [paper])

  return (
    <>
      <section className="ov-hero">
        <p className="eyebrow">Uniswap v4 hook · multi-stablecoin baskets</p>
        <h1>
          Stablecoin baskets with a <em>floor</em>.
        </h1>
        <p className="lede">
          A Uniswap v4 hook for multi-stablecoin pools. If any one coin fails, LP loss is capped at that coin's{' '}
          <span className="math">weight × (1 + budget)</span>, fixed at deployment and proved in the yellow paper
          (Theorem T4).
        </p>
        <p className="status-line" role="note">
          <AlertIcon width={16} height={16} />
          Research prototype · Simulation only · Unaudited · Not deployed
        </p>
        <div className="hero-cta">
          <button className="primary" onClick={() => scrollTo('fail')}>
            See a coin fail
          </button>
          <a className="secondary" href="#/paper">
            Read the yellow paper
          </a>
          <a className="ghost" href={REPO} target="_blank" rel="noreferrer">
            View the code <ArrowUpRight />
          </a>
        </div>
      </section>

      <section className="ov-section" aria-labelledby="verify-h">
        <h2 id="verify-h" className="ov-h">
          What's verified, and what isn't
        </h2>
        <ul className="verify card">
          {VERIFY.map((v) => (
            <li key={v.label}>
              <span
                className={`v-icon ${v.status}`}
                aria-label={v.status === 'done' ? 'done' : v.status === 'pending' ? 'in progress' : 'not yet'}
              >
                {v.status === 'done' ? <CheckIcon width={14} height={14} /> : v.status === 'pending' ? '…' : '—'}
              </span>
              <span className="v-label">{v.label}</span>
              {v.href ? (
                <a
                  className="v-value mono"
                  href={v.href}
                  {...(v.href.startsWith('http') ? { target: '_blank', rel: 'noreferrer' } : {})}
                >
                  {v.value}
                </a>
              ) : (
                <span className="v-value mono">{v.value}</span>
              )}
            </li>
          ))}
        </ul>
      </section>

      <section id="fail" className="ov-section" aria-labelledby="fail-h">
        <h2 id="fail-h" className="ov-h">
          What happens when a coin fails
        </h2>
        <p className="muted ov-sub">
          An attacker mints an unlimited amount of a broken coin and takes the best mix of good coins the pool will give
          up. Pick the coin that fails.
        </p>
        <div className="card fail">
          <div className="fail-controls">
            <div className="seg" role="radiogroup" aria-label="Pool">
              {(['3pool', 'paper'] as const).map((id) => (
                <button
                  key={id}
                  role="radio"
                  aria-checked={presetId === id}
                  className={presetId === id ? 'on' : ''}
                  onClick={() => {
                    setPresetId(id)
                    setCoin(0)
                  }}
                >
                  {id === '3pool' ? '3pool, b = 30%' : 'Paper vector'}
                </button>
              ))}
            </div>
            <div className="seg" role="radiogroup" aria-label="Coin that fails">
              {pr.params.symbols.map((s, i) => (
                <button
                  key={s}
                  role="radio"
                  aria-checked={h === i}
                  className={h === i ? 'on' : ''}
                  onClick={() => setCoin(i)}
                >
                  <i className="swatch" style={{ background: `var(--c${i % 5})` }} />
                  {s}
                </button>
              ))}
            </div>
          </div>

          <div className="fail-bars">
            <div className="bar-row">
              <div className="bar-label">
                <span>StableSwap, same reserves</span>
                <b className="mono bad">no floor</b>
              </div>
              <div className="bar">
                <div className="bar-fill bad" style={{ transform: 'scaleX(1)' }} />
              </div>
              <span className="muted small">
                Loss keeps growing toward the whole pool as the dump grows (paper §7).
              </span>
            </div>
            <div className="bar-row">
              <div className="bar-label">
                <span>Fermi, LP loss after an unlimited dump</span>
                <b className="mono accent">{pct(result.lossPct, 1)}</b>
              </div>
              <div className="bar">
                <div className="bar-fill accent" style={{ transform: `scaleX(${result.lossPct})` }} />
                <div className="bar-floor" style={{ left: `${floor * 100}%` }} />
              </div>
              <span className="muted small">
                Stops at the T4 floor of {pct(floor, 1)} = w·(1 + b) for {pr.params.symbols[h]}, with w ={' '}
                {pct(pr.params.w[h], 1)}, b = {pct(pr.params.b[h], 0)}.
              </span>
            </div>
          </div>
          <p className="muted small">
            In calm markets the same pool quotes within basis points of 1:1. Try it on the <a href="#/swap">Swap</a>{' '}
            tab.
          </p>
        </div>
      </section>

      <section className="ov-section ov-how" aria-labelledby="how-h">
        <div>
          <h2 id="how-h" className="ov-h">
            How it works
          </h2>
          <ol className="cases">
            <li>
              <b>Below its wall</b>, a coin swaps within basis points of 1:1.
            </li>
            <li>
              <b>Near the wall</b>, each extra unit buys less. At the wall it is worth half.
            </li>
            <li>
              <b>Past the wall</b>, the pool refuses what it can't absorb, so a dead coin can only take what its budget
              allowed.
            </li>
          </ol>
        </div>
        <div className="card">
          <OccupancyChart pool={howPool} coin={0} preview={null} unit={paper.unit} />
        </div>
      </section>

      <section className="ov-section" aria-labelledby="thm-h">
        <h2 id="thm-h" className="ov-h">
          The claim, with its conditions
        </h2>
        <div className="theorem-box">
          <span className="mono t-id">Theorem T4 · yellow paper §4</span>
          <p className="math big">
            LP loss ≤ w<sub>h</sub>·V·(1 + b<sub>h</sub>) + ε₀
          </p>
          <ul>
            <li>Holds for any swap path, any starting skew and any dump size. The bound is tight.</li>
            <li>
              Several failures: loss ≤ min(V, Σ w<sub>h</sub>c<sub>h</sub> + ε₀). Treat correlated coins as one set.
            </li>
          </ul>
          <p className="muted small limits">
            <b>What it doesn't cover:</b> smart-contract, oracle and frontend risk. It assumes the invariant is enforced
            exactly. Parameter ramps can be sandwiched within each step. It is built for permanent failures: if a coin
            re-pegs, Curve LPs would have recovered too (§10).
          </p>
          <a className="link" href={`${PAPER_SRC}#t4--loss-floor-path-independent`} target="_blank" rel="noreferrer">
            Read the proof
          </a>
        </div>
      </section>

      <section className="ov-section" aria-labelledby="cmp-h">
        <h2 id="cmp-h" className="ov-h">
          How it compares
        </h2>
        <div className="card table-wrap">
          <table className="compare">
            <thead>
              <tr>
                <th scope="col" />
                <th scope="col" className="accent">
                  Fermi
                </th>
                <th scope="col">Curve StableSwap</th>
                <th scope="col">Uniswap StablePair hook</th>
                <th scope="col">Plain v4 pool</th>
              </tr>
            </thead>
            <tbody>
              {COMPARE.map((r) => (
                <tr key={r.row} className={r.strong ? 'strong' : ''}>
                  <th scope="row">{r.row}</th>
                  {r.cells.map((c, k) => (
                    <td key={k} className={k === 0 ? 'fermi' : ''}>
                      {c}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="muted small ov-note">
          StablePair details from{' '}
          <a
            href="https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160"
            target="_blank"
            rel="noreferrer"
          >
            The Block, 2026-09-10
          </a>
          . Curve figures from the yellow paper §7. Fermi is unaudited and undeployed; the others hold real funds.
        </p>
      </section>

      <section className="ov-section" aria-labelledby="who-h">
        <h2 id="who-h" className="ov-h">
          Who it's for
        </h2>
        <div className="audiences">
          <div className="card">
            <h3>Liquidity providers</h3>
            <p className="muted">
              One deposit across several stablecoins. Before you deposit, you know the most a failed coin can cost: it
              is set at deployment.
            </p>
          </div>
          <div className="card">
            <h3>Traders</h3>
            <p className="muted">
              Swap any coin in the basket near 1:1 through standard Uniswap routing. Every pair settles against the same
              reserves.
            </p>
          </div>
          <div className="card">
            <h3>Integrators</h3>
            <p className="muted">
              A v4 hook with a custom curve via <code>beforeSwapReturnDelta</code>. Capacity per pair is a closed form
              (T5), so routers can size orders before splitting.
            </p>
          </div>
        </div>
      </section>

      <section className="ov-section" aria-labelledby="made-h">
        <h2 id="made-h" className="ov-h">
          How it's made
        </h2>
        <ol className="made card">
          <li>
            <b>Fermi hook</b> <span className="chip">in progress</span>
            <span className="muted">
              Replaces the v4 curve in <code>beforeSwap</code>. Native liquidity is disabled, so reserves only change
              through the invariant.
            </span>
          </li>
          <li>
            <b>Shared basket</b> <span className="chip">in progress</span>
            <span className="muted">
              One reserve set, with every pair registered as a v4 pool, held as ERC-6909 claims in the PoolManager.
            </span>
          </li>
          <li>
            <b>Math library</b> <span className="chip">specified</span>
            <span className="muted">
              Fixed-point exp/ln with every exponent kept non-positive. Rounding never favours the trader (§8).
            </span>
          </li>
          <li>
            <b>Simulator</b> <span className="chip done">done</span>
            <span className="muted">
              This app: a TypeScript port of §6.1 and §6.2, checked against the paper's test vectors.
            </span>
          </li>
        </ol>
      </section>

      <section className="ov-section ov-context" aria-labelledby="ctx-h">
        <h2 id="ctx-h" className="ov-h">
          Why stablecoin pools on v4
        </h2>
        <dl className="stats">
          <div className="stat">
            <dt>Stable-to-stable swaps on Uniswap, Q2 2026</dt>
            <dd className="mono">$43.4B</dd>
          </div>
          <div className="stat">
            <dt>Volume through v4 hooks</dt>
            <dd className="mono">&gt;$38B</dd>
          </div>
          <div className="stat">
            <dt>Hooks initialised</dt>
            <dd className="mono">&gt;90,000</dd>
          </div>
        </dl>
        <p className="muted small ov-note">
          Ecosystem figures as reported by{' '}
          <a
            href="https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160"
            target="_blank"
            rel="noreferrer"
          >
            The Block
          </a>
          . They are not Fermi volume. Fermi has none.
        </p>
      </section>
    </>
  )
}
