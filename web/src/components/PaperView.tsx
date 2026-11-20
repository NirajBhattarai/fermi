import { PAPER_PDF, PAPER_SRC, REPO } from '../lib/links'
import { ArrowUpRight } from './icons'

const CONTENTS = [
  'Notation and conventions',
  'The transform',
  'The balanced invariant',
  'Theorems T1–T6',
  'Parameterisation',
  'State transitions',
  'Comparison with StableSwap',
  'Numerical implementation',
  'Uniswap v4 hook mapping',
  'Security considerations',
  'Known limits',
  'Test vectors',
]

export function PaperView() {
  return (
    <>
      <div className="page-head">
        <div>
          <p className="eyebrow">Draft v0.1 · 2026-11-19 · 11 pages</p>
          <h1>The Balanced Fermi–Dirac AMM</h1>
          <p className="muted">
            The formal specification: definitions, theorems, state transitions, fixed-point and v4 hook rules, and test
            vectors. Every number in this app comes from these equations.
          </p>
        </div>
        <div className="page-actions">
          <a className="primary" href={PAPER_PDF} download="fermi-yellow-paper.pdf">
            Download PDF
          </a>
          <a className="secondary" href={PAPER_PDF} target="_blank" rel="noreferrer">
            Open <ArrowUpRight />
          </a>
        </div>
      </div>

      <div className="paper-intro">
        <div className="theorem-box">
          <span className="mono t-id">Main result · Theorem T4</span>
          <p className="math big">
            LP loss ≤ w<sub>h</sub>·V·(1 + b<sub>h</sub>) + ε₀
          </p>
          <p className="muted small">
            For any coin h that fails, along any swap path and for any dump size. Tight as the dump grows.
          </p>
        </div>
        <div className="card cite">
          <h3>Reproduce and cite</h3>
          <p className="muted small">Every number in §12 is printed by one script:</p>
          <code className="block">python3 tools/yellowpaper_vectors.py</code>
          <p className="muted small">
            Fermi contributors, <i>The Balanced Fermi–Dirac AMM: Yellow Paper</i>, draft v0.1, 2026-11-19.{' '}
            <a href={REPO} target="_blank" rel="noreferrer">
              github.com/NirajBhattarai/fermi
            </a>
          </p>
        </div>
      </div>

      <div className="grid-paper">
        <aside className="card paper-toc" aria-labelledby="toc-h">
          <h3 id="toc-h">Contents</h3>
          <ol>
            {CONTENTS.map((c) => (
              <li key={c}>{c}</li>
            ))}
          </ol>
          <a className="link" href={PAPER_SRC} target="_blank" rel="noreferrer">
            Markdown source on GitHub
          </a>
        </aside>

        <div className="card paper-frame">
          <object data={`${PAPER_PDF}#view=FitH`} type="application/pdf" aria-label="Fermi yellow paper (PDF)">
            <div className="paper-fallback">
              <p>Your browser can't show the PDF inline.</p>
              <a className="primary" href={PAPER_PDF} download="fermi-yellow-paper.pdf">
                Download PDF
              </a>
            </div>
          </object>
        </div>
      </div>
    </>
  )
}
