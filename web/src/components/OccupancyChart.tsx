import { useRef, useState } from 'react'
import { fPrime, phi, wall, type PoolState } from '../lib/fermi'
import { fmt, fmtAmt } from '../lib/format'
import type { Unit } from '../lib/presets'

const W = 640
const H = 250
const PAD = { l: 44, r: 18, t: 18, b: 34 }

interface Props {
  pool: PoolState
  coin: number
  preview: number[] | null
  unit: Unit
}

/**
 * Marginal value of one coin against its own reserve: f'(r) / φ.
 * Flat at par below the wall, half value at the wall, then falls away.
 */
export function OccupancyChart({ pool, coin, preview, unit }: Props) {
  const { params: p, V, x } = pool
  const w = p.w[coin]
  const wallX = wall(p, V, coin)
  const target = w * V
  const now = x[coin]
  const next = preview?.[coin]
  const xMax = Math.max(wallX * 1.35, now * 1.08, (next ?? 0) * 1.08)
  const ph = phi(p.R)
  const value = (X: number) => fPrime(p, V, coin, Math.max(X, 1e-12) / w) / ph

  const sx = (X: number) => PAD.l + (X / xMax) * (W - PAD.l - PAD.r)
  const sy = (v: number) => PAD.t + (1 - v / 1.08) * (H - PAD.t - PAD.b)

  const pts: string[] = []
  const N = 240
  for (let k = 0; k <= N; k++) {
    const X = (xMax * k) / N
    pts.push(`${k === 0 ? 'M' : 'L'}${sx(X).toFixed(2)},${sy(value(X)).toFixed(2)}`)
  }
  const path = pts.join('')

  const svgRef = useRef<SVGSVGElement>(null)
  const [hoverX, setHoverX] = useState<number | null>(null)

  const onMove = (e: React.PointerEvent) => {
    const r = svgRef.current?.getBoundingClientRect()
    if (!r) return
    const px = ((e.clientX - r.left) / r.width) * W
    const X = ((px - PAD.l) / (W - PAD.l - PAD.r)) * xMax
    setHoverX(X >= 0 && X <= xMax ? X : null)
  }

  const sym = p.symbols[coin]
  const color = `var(--c${coin % 5})`

  return (
    <figure className="chart">
      <svg
        ref={svgRef}
        viewBox={`0 0 ${W} ${H}`}
        role="img"
        aria-label={`Marginal value of ${sym} against its reserve. Wall at ${fmt(wallX)}; current reserve ${fmt(now)}.`}
        onPointerMove={onMove}
        onPointerLeave={() => setHoverX(null)}
      >
        <defs>
          <pattern id="hatch" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
            <line x1="0" y1="0" x2="0" y2="6" stroke="var(--accent)" strokeOpacity="0.22" strokeWidth="2" />
          </pattern>
        </defs>

        {/* past-the-wall region */}
        <rect x={sx(wallX)} y={PAD.t} width={sx(xMax) - sx(wallX)} height={H - PAD.t - PAD.b} fill="url(#hatch)" />

        {/* grid */}
        {[0, 0.5, 1].map((v) => (
          <g key={v}>
            <line x1={PAD.l} x2={W - PAD.r} y1={sy(v)} y2={sy(v)} className="grid" />
            <text x={PAD.l - 8} y={sy(v) + 4} className="tick" textAnchor="end">
              {v.toFixed(1)}
            </text>
          </g>
        ))}
        <line x1={PAD.l} x2={W - PAD.r} y1={sy(0)} y2={sy(0)} className="axis" />

        {/* target + wall markers */}
        <line x1={sx(target)} x2={sx(target)} y1={PAD.t} y2={sy(0)} className="marker" />
        <text x={sx(target)} y={H - 12} className="tick" textAnchor="middle">
          target
        </text>
        <line x1={sx(wallX)} x2={sx(wallX)} y1={PAD.t} y2={sy(0)} className="marker wall" />
        <text x={sx(wallX)} y={H - 12} className="tick wall" textAnchor="middle">
          wall
        </text>

        <path
          key={`${p.symbols.join()}-${coin}`}
          className="curve-draw"
          pathLength={1}
          d={path}
          fill="none"
          stroke={color}
          strokeWidth="2.25"
        />

        {/* preview */}
        {next !== undefined && Math.abs(next - now) > 1e-12 && (
          <g className="preview">
            <line
              x1={sx(now)}
              x2={sx(next)}
              y1={sy(value(now))}
              y2={sy(value(next))}
              stroke={color}
              strokeDasharray="3 3"
            />
            <circle cx={sx(next)} cy={sy(value(next))} r="5" fill="var(--surface)" stroke={color} strokeWidth="2" />
          </g>
        )}
        <circle
          className="dot-now"
          r="5.5"
          fill={color}
          stroke="var(--surface)"
          strokeWidth="2"
          style={{ transform: `translate(${sx(now)}px, ${sy(value(now))}px)` }}
        />

        {hoverX !== null && (
          <g className="hover">
            <line x1={sx(hoverX)} x2={sx(hoverX)} y1={PAD.t} y2={sy(0)} />
            <circle cx={sx(hoverX)} cy={sy(value(hoverX))} r="3.5" fill="var(--text)" />
            <text x={Math.min(sx(hoverX) + 8, W - PAD.r - 150)} y={PAD.t + 14} className="hover-label">
              {fmtAmt(hoverX, unit, 2)} → {value(hoverX).toFixed(4)}×
            </text>
          </g>
        )}
      </svg>
      <figcaption>
        <span>
          <i className="swatch" style={{ background: color }} /> {sym} reserve →
        </span>
        <span className="muted">y: marginal value vs. par, f′(r)/φ</span>
      </figcaption>
    </figure>
  )
}
