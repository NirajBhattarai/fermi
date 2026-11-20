import type { PoolParams } from './fermi'

export interface Unit {
  prefix: string
  suffix: string
  dp: number
}

export interface Preset {
  id: string
  name: string
  note: string
  params: PoolParams
  V: number
  unit: Unit
}

export const PRESETS: Preset[] = [
  {
    id: 'paper',
    name: 'Yellow-paper vector',
    note: 'USDC / USDT / NEW at a 100 / 50 / 10 target mix (§12). A young coin gets a tight 10% budget.',
    params: { symbols: ['USDC', 'USDT', 'NEW'], w: [0.625, 0.3125, 0.0625], b: [0.4, 0.4, 0.1], R: 10 },
    V: 160,
    unit: { prefix: '', suffix: '', dp: 4 },
  },
  {
    id: '3pool',
    name: '3pool, 30% budget',
    note: 'Equal-weight DAI / USDC / USDT at the live 3pool size. On StableSwap a one-coin failure has no floor; here LP loss is capped at 43% (paper §7).',
    params: { symbols: ['DAI', 'USDC', 'USDT'], w: [1 / 3, 1 / 3, 1 / 3], b: [0.3, 0.3, 0.3], R: 10 },
    V: 158.7,
    unit: { prefix: '$', suffix: 'M', dp: 3 },
  },
  {
    id: 'five',
    name: 'Five-coin basket',
    note: 'A curated mix where newer coins are held lightly and given small budgets, so each one carries little tail risk.',
    params: {
      symbols: ['USDC', 'USDT', 'DAI', 'PYUSD', 'NEW'],
      w: [0.4, 0.3, 0.15, 0.1, 0.05],
      b: [0.35, 0.35, 0.25, 0.15, 0.08],
      R: 12,
    },
    V: 1000,
    unit: { prefix: '$', suffix: 'k', dp: 2 },
  },
]
