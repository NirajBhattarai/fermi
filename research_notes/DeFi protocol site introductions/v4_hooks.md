# How Uniswap v4 hook projects and hookathon entries introduce themselves (2024–2026)

Scope note: Many hook homepages are JS-rendered SPAs (bunni.xyz, flaunch.gg, sorellalabs.xyz), so fetches returned only `<title>` tags. The Atrium UHI Hook Directory (hooks.atrium.academy, which redirects to Notion) could not be read either. Where only a title was available, it is quoted and marked. Zora/Clanker, Panoptic-on-v4 and Arrakis were not reached within the tool budget (see Gaps).

## 1. How notable v4 hook projects present themselves

### Takeaway
Mature hook projects almost never lead with "we are a hook". They lead with an outcome-led, product-category one-liner ("Token launches that work.", "The Shapeshifting Exchange", "Fair Markets for All DeFi Users"). "Built on Uniswap v4" shows up as a secondary credibility or distribution line, usually in the tagline footer, the GitHub "About" text or the docs intro. Docs intros then split benefits by audience (LPs / traders / token issuers or integrators).

### Cited Findings

**Bunni v2 (rehypothecation / custom liquidity shapes)**
- Page title: "Bunni - The Shapeshifting Exchange" (only the title rendered) — [bunni.xyz](https://bunni.xyz)
- GitHub About: "Shapeshifting DEX that maximizes liquidity provider profits in all market conditions. Built on Uniswap v4." — [GitHub bunniapp/bunni-v2](https://github.com/bunniapp/bunni-v2)
- README opener: "Bunni v2 is a next-gen decentralized exchange with shapeshifting liquidity, the next breakthrough in AMM design". The README now also opens with a warning, "Bunni v2 has been exploited," and "Please do not use this code in production as is." The README itself is otherwise just dev setup (Installation, Local development, Medusa fuzzing, Contract deployment). It does not explain hooks or LDFs. — [GitHub](https://github.com/bunniapp/bunni-v2)
- Docs intro: "Bunni v2 is a revolutionary Automated Market Maker (AMM) that introduces several groundbreaking features to optimize liquidity provision … maximize profits for liquidity providers (LPs)." It anchors on a familiar concept: "Building upon the concept of ticks from Uniswap v3 … introduces a new paradigm in decentralized exchange technology." — [Bunni docs overview](https://docs.bunni.xyz/docs/v2/overview)
- Docs feature bullets each pair a named mechanism with a benefit:
  - LDFs "Enable efficient liquidity distribution, modification, and swaps with constant gas costs."
  - Shapeshifting: "Allow LPs to provide liquidity in complex shapes and seamlessly shift or switch between these shapes"
  - Surge Fee: "Protect against sandwiching attacks during autonomous liquidity modifications."
  - The list also includes autonomous rebalancing, rehypothecation, am-AMM, volatility-based fees and auto-compounding.
  - The docs overview does not mention "Uniswap v4" or "hooks" at all.
  - Source: [Bunni docs](https://docs.bunni.xyz/docs/v2/overview)
- The Uniswap Foundation Hook Design Lab labels Bunni "Rehypothecation": "offers liquidity density functions, rehypothecation, autonomous rebalancing, and shapeshifting." — [UF Hook Design Lab](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab)

**EulerSwap (custom curve plus lending; closest architectural analogue to Fermi)**
- "EulerSwap is a new decentralized exchange that integrates directly with Euler's lending infrastructure and leverages Uniswap v4's hook architecture." — [Euler docs](https://docs.euler.finance/concepts/advanced/euler-swap) (via search snippet)
- Integrator framing: "EulerSwap is built to be fully compatible with Uniswap v4's hook architecture. This means it can plug into Uniswap's routing and solver networks while extending functionality with lending-based logic." — [Euler blog, Introducing EulerSwap](https://www.euler.finance/blog/introducing-eulerswap) (search snippet; the page now returns 404)
- Trader framing, where the hook is deliberately invisible: "Users can interact with EulerSwap through standard swap interfaces, unaware that beneath the surface, borrowing, lending, and advanced execution logic are taking place." — same source (search snippet)
- LP framing, "one deposit, three jobs": "Liquidity providers deposit assets that simultaneously earn lending yield, facilitate swaps, and can be used as collateral to borrow other tokens." — [UF Hook Design Lab](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab)
- Press angle: "route LP deposits into lending vaults, letting capital earn swap fees, lending yield and collateralize borrows in one system" — [The Block, May 2025](https://www.theblock.co/post/356004/euler-to-launch-eulerswap-dex-with-lending-boosted-yield)
- Builder entry point: a separate "Maglev" UI for creating EulerSwap operators, plus an open-source GitHub repo — [Euler blog snippet](https://www.euler.finance/blog/introducing-eulerswap)

**Doppler (token-launch hook)**
- Hero: "Token launches that work." Subhead: "Doppler lets you dial in tokenomics, launch with real price discovery, and graduate to deep liquidity" (it goes on to name an all-in-one app and a TypeScript SDK) — [doppler.lol](https://www.doppler.lol)
- CTAs split by audience:
  - Users: "Launch a token", "Explore markets"
  - Integrators: "Start building", "Read the docs", "View examples"
  - Researchers: "Read the paper"
  - Partners: "Contact us"
  - Source: [doppler.lol](https://www.doppler.lol)
- Structure:
  - A three-step "How it works": "Create the market", "Let price form", "Graduate liquidity"
  - Then "Your token, your way." and a "Why Doppler" grid: "MEV-resistant launches", "Capital efficient by design", "Seamless Uniswap migration", "Governance & treasuries", "Composable & programmable", "Scheduled launches", "Bespoke token economics"
  - Then "Read the whitepapers" and a closing "Ready to launch?"
  - Source: [doppler.lol](https://www.doppler.lol)
- Proof points: live networks (Base, Monad, Ethereum Mainnet) and live market cards with market caps. Uniswap is mentioned only as the destination: "Tokens and LP positions automatically migrate to Uniswap v2 or v4 once liquidity goals are met." The word "hook" is not used. — [doppler.lol](https://www.doppler.lol)

**Flaunch (launch hook)**
- Page title only: "Flaunch - Launch. Trade. Earn." (SPA; no other copy rendered) — [flaunch.gg](https://flaunch.gg)

**Angstrom / Sorella Labs (MEV/LVR-protection hook)**
- Company site title: "Sorella Labs | Fair Markets for All DeFi Users". The nav shows Dashboard, Explorer, Careers, Writing, so the entry points are a live dashboard and an explorer. — [sorellalabs.xyz](https://sorellalabs.xyz)
- Docs one-liner: "Angstrom is a new kind of DEX built on top of Uniswap V4 that internalizes its MEV through application-level sequencing." — [docs.angstrom.xyz](https://docs.angstrom.xyz)
- LP pitch names the problem in plain words: "Traditional AMMs leak immense value to arbitrageurs" (Loss-Versus-Rebalancing). LPs "retain their value when prices move instead of losing to arbitrage." — [Angstrom docs](https://docs.angstrom.xyz)
- Trader pitch: "All trades in a block clear at a uniform price" (no sandwiches), gasless swaps — [Angstrom docs](https://docs.angstrom.xyz)
- Docs structure: "Why use Angstrom?" split into **For Liquidity Providers / For Traders / For Token Issuers**, then "The Problem", architecture (L1 vs L2) and API reference — [Angstrom docs](https://docs.angstrom.xyz)

**Uniswap's own StablePair Hook (Sept 2026; direct competitor in the stablecoin-pair space)**
- "a new Uniswap v4 hook designed for stablecoin trading pairs such as USDC/USDT and USDC/USDG" — [The Block, 2026-09-10](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Two-audience one-liner: "StablePair Hook gives traders consistent, predictable quotes on every swap, and LPs a bigger share of the value they create" — Uniswap Labs, via [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Mechanics as described:
  - "a dynamic fee in place of a fixed fee" that changes with distance from a reference price, to "maintain a fixed spread"
  - Trades that push the price further away "pay no fee"
  - A Dutch auction where "The fee starts high and falls with each block until a trader accepts it," which "allows liquidity providers to keep more of the value from bringing the price back"
  - Upgradable via governance without migrating liquidity
  - Source: [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Ecosystem metrics Uniswap uses as context:
  - "Stablecoin-to-stablecoin swaps on Uniswap reached $43.4 billion in the second quarter"
  - "More than $38 billion in swap volume has flowed through v4 hooks to date"
  - "More than 90,000 hooks have been initialized across 20 chains"
  - Source: [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)

**Other stableswap / custom-curve hooks (developer-facing only)**
- Revert Finance "StableSwap Hooks": a v4 hook bringing Curve-style StableSwap to v4 pools. It surfaced as a 2026 Cantina audit competition, not a marketing site. — [Cantina](https://cantina.xyz/competitions/e55ee7b9-6c99-42f8-8338-39f3dd134ef3)
- robertleifke/stableswap: described in listings as a stablecoin exchange on v4 using a constant-sum curve via OpenZeppelin's BaseCustomCurve. The listing page itself returned 403, so this rests on the search summary only. — [ecosyste.ms listing](https://awesome.ecosyste.ms/projects/github.com%2Frobertleifke%2Fstableswap)
- The Atrium "Request for Hooks" page lists custom curves such as a CSMM NoOp hook (x + y = k) and a "LAMMBert" curve as suggested ideas — [Atrium Request for Hooks](https://atriumacademy.notion.site/atrium-academy-request-for-hooks) (via search summary)

**Uniswap Foundation Hook Design Lab (how UF itself catalogues hooks)**
- Hooks are grouped into categories, each defined in one plain sentence:
  - JIT Liquidity: "Hooks that allow LPs to deposit funds into a trading pool at the exact moment a swap is initiated."
  - Dynamic Fees: "Hooks that allow pool creators to implement fees that can change with custom variables."
  - Rehypothecation: "Hooks that allow LPs to reuse deposited liquidity while it's in the pool."
  - Each entry is team name (org), a bold "Hook Type" label, and one paragraph.
  - Source: [UF Hook Design Lab](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab)
- Example entries:
  - Aegis (Solo Labs): "introduces a fully on-chain, self-regulating dynamic fee system built with Uniswap v4 hooks."
  - Dynamo DEX (Renzo): "a dynamic fee hook that's specifically designed to maintain price stability for pegged LRT assets."
  - Source: [UF Hook Design Lab](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab)

### Inferences
- The pattern is **outcome or category first, mechanism second, "on Uniswap v4" third**. Even EulerSwap, which uses a custom curve, leads with "new DEX", not "hook".
- Mature projects target three audiences:
  - **Traders**: the hook is invisible ("standard swap interfaces, unaware…")
  - **LPs**: a named loss mechanism plus how it is stopped (LVR, sandwich, idle capital)
  - **Integrators**: "plugs into Uniswap routing and solvers", SDK and docs CTAs
- Uniswap's own StablePair Hook now owns the plain phrase "stablecoin pairs + LPs keep more value". Fermi will need to separate itself on *multi-asset baskets* and a *provable loss floor*. StablePair's pitch is about fees and spread, not a guaranteed bound.
- Bunni's exploit warning shows how a security incident overrides any hero copy. Hookathon judges are likely primed to look for invariants and tests, and a "provable LP loss floor" speaks directly to that.

### Gaps
- Live hero copy for flaunch.gg, bunni.xyz and Angstrom's app is not readable (JS-rendered).
- Zora / Clanker launch hooks, Panoptic-on-v4 and Arrakis (v4 modules) were not researched within the tool budget.
- The EulerSwap launch blog now 404s. Its quotes come from search snippets only.
- Bunni's operational status after the exploit is not sourced here beyond the README warning.

## 2. What winning hookathon submissions include, and what judges value

### Takeaway
No published scoring rubric was found for UHI or Uniswap hookathons. The verifiable signals are these:
- Organisers check that the integration is **real and verifiable**: README pointers to exact contracts and lines, and on-chain proof such as callbacks actually firing.
- Winner write-ups compress each project to a **one-line problem/solution**.
- Demo Day panels include VCs, so pitches are judged partly as investable products.

### Cited Findings
- ETHGlobal Tokyo 2026 Uniswap Foundation prize requirements:
  - "A public GitHub repository with open-source code, a FEEDBACK.md file," plus a Uniswap Developer Feedback Form
  - "Submissions without it will be reviewed and audited before winners are finalized."
  - "Make sure your README clearly points to the relevant contracts and lines of code so we can verify your integration."
  - No other judging criteria are listed.
  - Source: [ETHGlobal Tokyo 2026 UF prizes](https://ethglobal.com/events/tokyo2026/prizes/uniswap-foundation)
- UHI9 Hookathon, Reactive Network track: judges checked whether each project's reactive contract **actually fired a callback on-chain**, and six projects passed. The write-up gives each project a "problem → solution" subtitle:
  - EvenFlow: "The Problem With Waiting for a Swap"
  - Unistrata: "Settling the Books With No One at the Desk"
  - TrancheShield: "A Risk Dial That Turns Itself"
  - lambda: "Hedging on a Market Your Hook Has Never Visited"
  - Maestro: "Letting a Contract Run the Pool"
  - Veritas: "What the Chain has Already Seen"
  - Source: [Reactive Network blog](https://blog.reactive.network/reactive-contracts-uniswap-hooks-the-first-wave-from-the-uhi9-hookathon/)
- Many UHI9 projects frame themselves around **LP loss**:
  - lambda: LPs lose to LVR, so positions are auto-hedged on Hyperliquid to stay near delta-neutral
  - TrancheShield: auto-adjusts fees and IL coverage
  - Unistrata: senior/junior tranches
  - Source: [Reactive blog](https://blog.reactive.network/reactive-contracts-uniswap-hooks-the-first-wave-from-the-uhi9-hookathon/)
- One UHI9 Demo Day was titled "The Yield-Protected AMM" — [Luma UHI9 Demo Day](https://luma.com/t8g1g8em) (title only, from search results)
- UHI10 Demo Day copy: "UHI is a developer bootcamp to speedrun building a Uniswap v4 hook … participating developers learn best practices for ideating, building and shipping a Uniswap hook within 9 weeks." It was streamed on YouTube. — [Luma UHI10](https://luma.com/atrium-xbgs)
- Program arc: "a capstone hookathon" then "a demo day where top projects are presented." — [UF Builder Stories, Bhaumik Patel](https://www.uniswapfoundation.org/blog/builder-stories-bhaumik-patel-on-the-uniswap-hook-incubator)
- UF's early UHI winner one-liners follow one format, *what it is + who benefits + how*:
  - UniCast: "Designed to improve LP experience in certain pools by incorporating forward-looking events"
  - Concentrated Incentives: "Optimizes liquidity incentives by incentivizing only the active tick."
  - Miladay Pools: "A dark pool implementation that allows a swapper to swap without disclosing their order to the wider market."
  - UniCow: "An actively validated service to enable Coincidence of Wants matching on any Uniswap v4 pool."
  - LVR & IL Hedgehook: "Improving LP experience with dynamic fees and dynamic hedging strategies."
  - Source: [UF Builder Stories](https://www.uniswapfoundation.org/blog/builder-stories-bhaumik-patel-on-the-uniswap-hook-incubator)
- UniCast was built by Gordon Liao (Chief Economist at Circle), a UHI graduate and hookathon winner — [UF grant to Atrium](https://uniswapfoundation.org/blog/announcing-usd1-2-million-grant-to-atrium-academy-to-expand-the-uniswap-hook-incubator)
- Judges named across UF/UHI events:
  - Hookathon C1 judges and speakers included saucepoint (UF devrel)
  - UF's Ken Ng judged a UHI Demo Day alongside investors from a16z, Variant, Dragonfly and USV
  - Kenneth Ng and Gordon Liao sat on the Unichain Infinite Hackathon committee
  - Source: search summaries of [LearnWeb3 Hookathon C1](https://learnweb3.io/hackathons/hookathon-c1/), [Luma UHI Demo Day](https://lu.ma/0p6uabf2), [UF Infinite Hackathon winners](https://uniswapfoundation.org/blog/announcing-the-first-unichain-infinite-hackathon-winners). These pages were not fetched directly.
- UHI6 winners per a UF builder update: azex (cross-chain execution), symbiote (composable hook primitives), flashfi (rehypothecation), unilend (lending markets) — [UF builder update, via search](https://uniswapfoundation.org/blog/builder-update-35) (attribution to that issue number is unverified)
- UHI9 winners were announced on Atrium Academy's X account (June 19), and one student won two categories — [UGM news](https://ugm.ac.id/en/news/ugm-student-wins-two-titles-at-international-uniswap-blockchain-competition/)
- ETHGlobal showcase page structure (example: StableFlow, HackMoney 2026, ENS prize):
  - Fields: Project name, "Created At" event, "Winner of" sponsor/track, Project Description, How it's Made, Tech Stack, Notable Design Decision, Partner Technologies, Source Code
  - Its tagline: "Cross-chain stablecoin liquidity rebalancing using Uniswap v4 intents and Arc settlement."
  - "How it's Made" is a numbered component list in ALL-CAPS headers, e.g. "UNISWAP V4 CUSTOM HOOK (Intent Emission Layer)", plus a frontend explicitly described as "VERIFICATION & OBSERVABILITY", a read-only trace dashboard
  - It includes the safety claim "Crucially, the hook never performs external calls or cross-chain actions."
  - Source: [ETHGlobal StableFlow](https://ethglobal.com/showcase/stableflow-v4sbe)

### Inferences
- The winning formula visible in the sources has five parts:
  1. A one-line "who is harmed → how the hook fixes it" statement
  2. A component breakdown that labels each layer's role
  3. Explicit safety or invariant claims ("never performs external calls")
  4. Verifiable proof: README line pointers, deployed testnet addresses, on-chain transactions or callbacks
  5. An observability dashboard
- Since Demo Day judges include VCs, an economic metric helps: LP loss bounded at X bps, compared with a v4 constant-product pool and Curve. Fermi's "provable loss floor" fits the "verify it on-chain" ethos well if it comes with a test, invariant or formal proof link.

### Gaps
- No official UHI / Atrium judging rubric or weights were found.
- The full UHI9/UHI10 winner lists and their submission pages (videos, decks) were not retrieved. The Atrium hook directory (Notion) did not render.
- Whether winners typically include demo videos could not be confirmed from primary sources.

## 3. How projects explain hook mechanics without losing non-technical readers

### Takeaway
Non-technical copy replaces mechanism names with **anchors and outcomes**:
- "builds on ticks from v3"
- "standard swap interfaces, unaware…"
- "clear at a uniform price"
- "LPs retain their value when prices move"

Permissions, deltas, ERC-6909 and `beforeSwapReturnDelta` were never found in hero or intro copy. They appear only in deeper docs and READMEs.

### Cited Findings
- Bunni anchors on a known concept ("Building upon the concept of ticks from Uniswap v3"). It gives each feature a one-clause benefit ("swaps with constant gas costs", "Protect against sandwiching attacks"), and its docs overview omits the words "hook" and "v4". — [Bunni docs](https://docs.bunni.xyz/docs/v2/overview)
- EulerSwap tells traders outright that the complexity is hidden ("unaware that beneath the surface, borrowing, lending… are taking place"). It tells integrators the hook means it "can plug into Uniswap's routing and solver networks". — [Euler blog snippet](https://www.euler.finance/blog/introducing-eulerswap)
- Angstrom names the LP problem in lay terms ("leak immense value to arbitrageurs") before naming LVR or the architecture — [Angstrom docs](https://docs.angstrom.xyz)
- Doppler swaps mechanism for a three-verb narrative ("Create the market → Let price form → Graduate liquidity") — [doppler.lol](https://www.doppler.lol)
- UF's category definitions are single sentences of the form "Hooks that allow LPs to …" — [UF Hook Design Lab](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab)
- StablePair Hook explains a dynamic fee through its effect ("consistent, predictable quotes") and a familiar auction metaphor ("starts high and falls with each block until a trader accepts it") — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)

### Inferences
- For Fermi, an equivalent ladder would be:
  - Traders: "swap any stablecoin in the basket at near-1:1, routed through Uniswap"
  - LPs: "one deposit across N stablecoins; the math guarantees your loss can't exceed X"
  - Integrators: "a v4 hook with its own pricing curve (it replaces v4's built-in swap math via `beforeSwapReturnDelta`), so any Uniswap router or solver reaches it"
- Name the curve in a plain metaphor before naming its permission flags.

### Gaps
- The Uniswap Help Center "What is a hook?" article (403) and the developers.uniswap.org custom-curve guide (404 at the tried URL) could not be fetched for verbatim user-facing definitions.

## 4. Common patterns and notable gaps

### Takeaway
The common patterns are an outcome-first hero, audience-split benefits, a three-step "how it works", live dashboard or explorer entry points, and "Built on Uniswap v4" used as distribution credibility. Three things are missing across the field: quantified, *provable* LP guarantees; plain-language custom-curve explanations; and multi-asset stablecoin basket hooks with consumer-grade pitches.

### Cited Findings
- Outcome-first heroes: "Token launches that work." ([Doppler](https://www.doppler.lol)); "The Shapeshifting Exchange" ([Bunni](https://bunni.xyz)); "Fair Markets for All DeFi Users" ([Sorella](https://sorellalabs.xyz)); "Launch. Trade. Earn." ([Flaunch](https://flaunch.gg))
- Benefits split by audience: Angstrom "For Liquidity Providers / For Traders / For Token Issuers" ([docs](https://docs.angstrom.xyz)); Doppler CTA split app vs SDK vs paper ([doppler.lol](https://www.doppler.lol))
- Papers and whitepapers as proof: Doppler "Read the paper" / "Read the whitepapers" ([doppler.lol](https://www.doppler.lol))
- Live entry points: Sorella "Dashboard" and "Explorer" ([sorellalabs.xyz](https://sorellalabs.xyz)); EulerSwap Maglev operator UI ([Euler blog snippet](https://www.euler.finance/blog/introducing-eulerswap)); StableFlow read-only verification dashboard ([ETHGlobal](https://ethglobal.com/showcase/stableflow-v4sbe))
- Ecosystem-scale numbers available for framing (v4 hooks volume >$38B, >90,000 hooks, stable-stable swaps $43.4B in Q2) — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Existing stablecoin-specific hooks are either Uniswap's own two-asset StablePair Hook ([The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)), audit-stage infrastructure ([Revert StableSwap Hooks, Cantina](https://cantina.xyz/competitions/e55ee7b9-6c99-42f8-8338-39f3dd134ef3)), or Dynamo DEX for pegged LRTs ([UF](https://uniswapfoundation.org/blog/introducing-the-uniswap-v4-hook-design-lab))

### Inferences
- **Gap Fermi can own:** no project found makes a *quantified, provable* LP loss bound its hero claim. Rivals say "maximize LP profits" (Bunni), "retain their value" (Angstrom) or "bigger share of the value" (StablePair). These are qualitative claims.
- **Gap:** no surveyed hero copy handles *N-asset stablecoin baskets* on v4. Pair-based hooks dominate.
- **Risk:** Uniswap's own StablePair Hook sets the default comparison. Fermi's page should probably include an explicit "vs. StablePair / vs. Curve / vs. plain v4 pool" table.
- **Pattern to copy:**
  - Hero outcome line
  - A one-sentence "for traders / for LPs / for integrators" triple
  - Three-step how-it-works
  - Proof strip (tests/invariants, the yellow paper, deployed addresses, a link into the verifying README lines)
  - Live demo CTA
  - ETHGlobal-style "How it's made" component list with explicit safety claims

### Gaps
- No quantitative data was found on which page structures convert better or score higher with judges.
- Zora, Clanker, Panoptic and Arrakis presentation patterns are unresearched here.
