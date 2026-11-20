import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { Basket } from './components/Basket'
import { Dashboard } from './components/Dashboard'
import { Overview } from './components/Overview'
import { AlertIcon, GitHubIcon, Logo } from './components/icons'
import { OccupancyChart } from './components/OccupancyChart'
import { PaperView } from './components/PaperView'
import { SwapCard, type Trade } from './components/SwapCard'
import { createPool } from './lib/fermi'
import { REPO } from './lib/links'
import { PRESETS } from './lib/presets'
import './App.css'

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'swap', label: 'Swap' },
  { id: 'paper', label: 'Yellow paper' },
] as const
type Tab = (typeof TABS)[number]['id']

const readTab = (): Tab => {
  const h = window.location.hash.replace(/^#\/?/, '')
  return (TABS.find((t) => t.id === h)?.id ?? 'overview') as Tab
}

function useHashTab() {
  const [tab, setTab] = useState<Tab>(readTab)
  useEffect(() => {
    const on = () => {
      setTab(readTab())
      window.scrollTo({ top: 0 })
    }
    window.addEventListener('hashchange', on)
    return () => window.removeEventListener('hashchange', on)
  }, [])
  return tab
}

/**
 * Active-tab indicator: a styled copy of the tab list, clipped to the active
 * tab. Text colour, background and underline move as one element.
 */
function TabNav({ tab }: { tab: Tab }) {
  const navRef = useRef<HTMLElement>(null)
  const [clip, setClip] = useState<string>()

  useLayoutEffect(() => {
    const nav = navRef.current
    const link = nav?.querySelector<HTMLElement>(`[data-tab="${tab}"]`)
    if (!nav || !link) return
    const update = () => {
      const right = nav.clientWidth - (link.offsetLeft + link.offsetWidth)
      setClip(`inset(0 ${right}px 0 ${link.offsetLeft}px round 8px)`)
    }
    update()
    const ro = new ResizeObserver(update)
    ro.observe(nav)
    ro.observe(link)
    return () => ro.disconnect()
  }, [tab])

  return (
    <nav ref={navRef} className="tabs" aria-label="Main">
      {TABS.map((t) => (
        <a key={t.id} data-tab={t.id} href={`#/${t.id}`} aria-current={tab === t.id ? 'page' : undefined}>
          {t.label}
        </a>
      ))}
      <div className="tabs-active" aria-hidden style={{ clipPath: clip }}>
        {TABS.map((t) => (
          <span key={t.id}>{t.label}</span>
        ))}
      </div>
    </nav>
  )
}

export default function App() {
  const tab = useHashTab()
  const [presetId, setPresetId] = useState(PRESETS[0].id)
  const preset = PRESETS.find((p) => p.id === presetId)!
  const [pool, setPool] = useState(() => createPool(preset.params, preset.V))
  const [preview, setPreview] = useState<number[] | null>(null)
  const [focus, setFocus] = useState(0)
  const [trades, setTrades] = useState<Trade[]>([])
  const unit = preset.unit

  const reset = (id = presetId) => {
    const pr = PRESETS.find((p) => p.id === id)!
    setPresetId(id)
    setPool(createPool(pr.params, pr.V))
    setTrades([])
    setFocus(0)
  }

  const onPreview = useCallback((x: number[] | null) => setPreview(x), [])
  const onExecute = (x: number[], t: Omit<Trade, 'id'>) => {
    setPool((s) => ({ ...s, x }))
    setTrades((ts) => [{ ...t, id: Date.now() }, ...ts].slice(0, 20))
  }

  const coin = Math.min(focus, pool.params.symbols.length - 1)

  return (
    <>
      <a className="skip" href="#main">
        Skip to content
      </a>
      <header className="topbar">
        <div className="wrap topbar-inner">
          <a href="#/overview" className="brand" aria-label="Fermi overview">
            <Logo />
            <span>Fermi</span>
          </a>
          <TabNav tab={tab} />
          <div className="topbar-right">
            <span className="chip sim" title="Computed in-browser from the yellow-paper invariant">
              <i className="dot" /> Simulation
            </span>
            <a className="icon-btn" href={REPO} target="_blank" rel="noreferrer" aria-label="GitHub repository">
              <GitHubIcon />
            </a>
          </div>
        </div>
      </header>

      <main id="main" key={tab} className="wrap page">
        {tab === 'overview' && <Overview />}

        {tab === 'dashboard' && (
          <Dashboard
            preset={preset}
            pool={pool}
            trades={trades}
            focus={coin}
            onFocus={setFocus}
            onPreset={reset}
            onReset={() => reset()}
          />
        )}

        {tab === 'swap' && (
          <>
            <div className="page-head">
              <div>
                <p className="eyebrow">{preset.name}</p>
                <h1>Swap</h1>
                <p className="muted">
                  Swaps stay within basis points of par until a coin reaches its wall. Past the wall each unit buys
                  less, and the pool refuses any trade it can't absorb.
                </p>
                <p className="status-line small" role="note">
                  <AlertIcon width={15} height={15} />
                  Simulation: no wallet, no chain, no funds move. Contracts are unaudited.
                </p>
              </div>
            </div>
            <div className="grid-swap">
              <div className="stack">
                <SwapCard pool={pool} unit={unit} onPreview={onPreview} onExecute={onExecute} onFocusCoin={setFocus} />
              </div>
              <div className="stack">
                <Basket pool={pool} preview={preview} unit={unit} focus={coin} onFocus={setFocus} />
                <section className="card" aria-labelledby="occ-h">
                  <header className="card-head">
                    <h3 id="occ-h">Occupancy curve · {pool.params.symbols[coin]}</h3>
                  </header>
                  <OccupancyChart pool={pool} coin={coin} preview={preview} unit={unit} />
                </section>
              </div>
            </div>
          </>
        )}

        {tab === 'paper' && <PaperView />}
      </main>

      <footer className="footer">
        <div className="wrap footer-inner">
          <span className="brand small">
            <Logo width={20} height={20} /> Fermi
          </span>
          <p className="muted small disclaimer">
            Research prototype. Not financial advice. Stablecoins can lose their peg, and a basket of stablecoins is not
            itself a stablecoin. Fermi bounds loss from a failed coin under stated parameters. It does not remove
            smart-contract, oracle or frontend risk.
          </p>
          <p className="muted small official">
            Official source:{' '}
            <a href={REPO} target="_blank" rel="noreferrer">
              github.com/NirajBhattarai/fermi
            </a>
            . Fermi has no token and asks for no deposits.
          </p>
        </div>
      </footer>
    </>
  )
}
