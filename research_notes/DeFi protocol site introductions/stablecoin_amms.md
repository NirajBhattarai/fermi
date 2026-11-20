# How Stablecoin AMMs and DEXs Introduce Themselves (Homepage / App Landing Catalogue)

Research date: 2026-11-19. Method: WebFetch of live homepages and docs, plus Chrome rendering for JS-only sites. Several homepages are client-rendered SPAs or block automated fetching: curve.finance stuck on a loading splash, balancer.fi returned HTTP 429 and denied browser read access, ekubo.org returned 403, mav.xyz returned only a title, and web.archive.org was unreachable. Where live copy could not be read, this file says so rather than reconstructing it from memory. Third-party mirror/"guide" sites (onrender.com, pages.dev, sites.google.com) showed up in search and are often phishing-style clones. Their copy is marked as unverified and should not be treated as official.

## Q1: What exact hero copy, sections, stats and CTAs do the established stablecoin AMMs use?

### Takeaway
The incumbents introduce themselves with very short, superlative, category-claiming headlines ("The Liquidity Layer For All Finance", "AMMs made easy", "The most advanced AMM ever", "The Future Of Onchain FX"). They rarely say "stablecoin" in the hero. Proof is carried by stat tiles such as volume, users, pool count and integrations, plus audit-logo strips. Primary CTAs are app-entry verbs ("Launch App", "Swap", "Lend"). Curve, the main stablecoin incumbent, puts almost no marketing on its root URL: the app shell loads behind a logo splash.

### Cited Findings

**Curve (curve.finance)**
- The root URL is a client-rendered app. In a real Chrome render, the first screen was the 3D rainbow-gradient Curve logo above a bold black sans-serif "Curve" wordmark and a loading spinner, on an off-white/warm-grey background. No headline text was rendered within ~10s. — [curve.finance (rendered 2026-11-19)](https://www.curve.finance/)
- The only machine-readable description is the meta tag: "Curve-frontend is a user interface application designed to connect to Curve's deployment of smart contracts." The tone is neutral and engineering-first, not marketing. — [curve.finance](https://www.curve.finance/)
- The docs hub headline is "Curve Knowledge Hub", with the subline "Your gateway to understanding and building with Curve - Documentation, metrics, and latest updates". Its sections run Users, Developers, Build on Curve, Interesting Reads. — [docs.curve.finance](https://docs.curve.finance/)
- The user intro opens with "Curve is a decentralized exchange (DEX) powered by automated market makers (AMMs)" and frames Curve as covering both stablecoins and volatile assets. It does not lead with "stablecoin". — [Curve user intro](https://docs.curve.finance/user/introduction)
- An unofficial onrender.com mirror shows the headline "Your Trusted Platform for Stablecoin Trading and DeFi Solutions". This is NOT verified as official and is likely a clone. — [project-curvefi.onrender.com (unofficial)](https://project-curvefi.onrender.com)

**Balancer (balancer.fi)**
- The live homepage could not be read (HTTP 429, browser read denied). The v3 docs homepage headline is "AMMs made easy", with the subheading "Learn, integrate, and build on a programmable AMM". — [docs.balancer.fi](https://docs.balancer.fi/) (via search snippet)
- A third-party mirror titled "Balancer—AMMs made easy" shows stat tiles: "Pools, 6.0k; 24hr volume, $86m; 10+ Aggregator Integrations". This suggests the stat-tile pattern is pools / 24h volume / aggregator integrations, but it is an unverified mirror. — [balancer-com.pages.dev (unofficial mirror)](https://balancer-com.pages.dev)
- Docs position v3 as "a simplified and more efficient AMM infrastructure, optimized for scalability and developer experience". — [Balancer docs intro](https://docs.balancer.fi/concepts/core-concepts/introduction.html)
- The Stable Pool page opens: "Stable Pools are designed for assets that are either expected to consistently swap at near parity" (or at a known exchange rate). It says "Stable Pools have a safe maximum of 5 tokens, due to the constraints of Stable Math". — [Balancer Stable Pool docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/stable-pool/stable-pool.html)

**Fluid (fluid.io / Instadapp)**
- The hero headline is "The Liquidity Layer For All Finance". The subheadline is "Finance's most capital-efficient liquidity layer." — [fluid.io](https://fluid.io/)
- The homepage has no content sections and no stat tiles. Navigation CTAs are "Lend", "Borrow", "Lite", "Support". Footer links include "Swap", "Refinance", "Stats", "Multiply", "Smart Lending", "Bug Bounty", "Transparency", "Risk Research". Risk is pushed to footer links, not shown on the page. — [fluid.io](https://fluid.io/)
- Docs describe the DEX as built "on top of the Liquidity Layer and cominbed [sic] with the Vault protocol" to enable "Smart collateral and Smart debt", which "allows users to earn LP fees whilst providing collateral or even on their borrowed debt position". — [Fluid docs](https://docs.fluid.instadapp.io/)

**Ekubo (ekubo.org)**
- The live site returned 403. A scraped copy shows the headline "The most advanced AMM ever" and the subline "Unmatched capital efficiency with concentrated liquidity, extensibility, and low fees". The copy is from a search scrape, not live-verified. — [ekubo.org (via search)](https://ekubo.org)
- The GitHub org describes it as a "next generation AMM on Ethereum and Starknet", "the most powerful AMM ever", and cites "100x concentrated liquidity, extensibility, and highly optimized smart contracts". — [EkuboProtocol GitHub](https://github.com/EkuboProtocol)
- Launch partner framing: "Introducing Ekubo: The Most Powerful AMM in Crypto". — [Argent blog](https://argent.xyz/blog/introducing-ekubo)
- Ekubo is not stablecoin-specific. Its positioning is general capital efficiency plus extensions (hooks-like).

**Maverick (mav.xyz)**
- The fetch returned only the page title "Maverick Protocol". No hero copy was retrievable. — [mav.xyz](https://www.mav.xyz/)
- A third-party comparison describes Maverick's mechanism as bins that "automatically redistribute liquidity as price moves", with recommended widths of 0.02–0.05% for stable pairs. It also notes that directional modes can create asymmetric IL. — [Spark stablecoin AMM comparison](https://www.spark.money/tools/stablecoin-automated-market-maker-comparison)

**Mento (mento.org), the richest homepage of the set (2026)**
- The hero headline is "The Future Of Onchain FX". The subheadline is "Mento is building the largest FX infrastructure, bringing world currencies onchain". — [mento.org](https://www.mento.org/)
- Sections in order:
  1. "Reshaping Global Finance by Bringing FX Onchain"
  2. "Bringing Stability to a Borderless Economy" (Reserve)
  3. "Start Using Mento Stablecoins"
  4. "Build on Mento Infrastructure"
  5. Ecosystem
  6. Feature cards "Decentralized / Transparent / Stable / Interoperable"
  7. "Discover the Possibilities with Mento"
  8. "Building Trust with Transparency"
  9. Blog
  10. Audits
  11. Closing tagline "Unifying global FX liquidity through a decentralized, multi-currency platform."
  12. Newsletter

  — [mento.org](https://www.mento.org/)
- Stat tiles: "12M+" users, "$18.5B" trading volume in 2025, "277M" transactions in 2025, "15" stablecoins live, "3:1" collateralization ratio. — [mento.org](https://www.mento.org/)
- CTAs: "Get Mento Stablecoins", "Swap Mento Stablecoins", "Launch App", "Integrate", "See Mento Reserve", "Contact the Mento Team". — [mento.org](https://www.mento.org/)
- The audit block lists ChainSecurity (Mento Core V3, Feb 2026), Hats.finance, Sherlock and 0xmacro. — [mento.org](https://www.mento.org/)

**PancakeSwap StableSwap**
- Docs headline "🏦Stableswap". Opening line: "StableSwap on PancakeSwap is a feature to trade stable pairs with a lower slippage based on an invariant curve". Further: "It is designed to swap specific assets that are priced closely." — [PancakeSwap docs](https://docs.pancake.xyz/trade/stableswap)
- Two variants are named. "Infinity StableSwap is built on PancakeSwap's latest Infinity architecture" and is credited with "improved flexibility, efficiency, and future extensibility". Classic StableSwap is the original implementation. — [PancakeSwap docs](https://docs.pancake.xyz/trade/stableswap)

**Uniswap StablePair Hook (newest direct comparable, launched Sept 2026)**
- Positioning: "a new Uniswap v4 hook designed for stablecoin trading pairs such as USDC/USDT and USDC/USDG". Value line: "StablePair Hook gives traders consistent, predictable quotes on every swap, and LPs a bigger share of the value they create." — [The Block, 2026-09-10](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Mechanism in plain language: it "uses a dynamic fee in place of a fixed fee that changes based on how far the pool price moves from its reference price". Trades pushing away from the reference price "pay no fee". Trades moving it back use "a Dutch auction. The fee starts high and falls with each block until a trader accepts it." — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Stats used in launch framing: stable-to-stable swaps on Uniswap "reached $43.4 billion in the second quarter, more than the next three onchain venues combined". "More than $38 billion in swap volume has flowed through v4 hooks". "More than 90,000 hooks have been initialized across 20 chains". — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- The launch coverage has no Curve comparison and no depeg/risk language. — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- An altfins summary reports "three hidden flaws" in StablePair that "drain LP returns". This is a secondary source and unverified. — [altfins](https://altfins.com/crypto-news/crypto-news-summary/467907)

**Other 2025–2026 v4-hook stablecoin projects (self-reported / hackathon)**
- Orbital describes itself as the first N-asset concentrated stableswap shipped as a live Uniswap v4 hook. The claim is self-reported and the Notion page could not be read. — [Orbital Notion](https://atriumacademy.notion.site/Orbital-37d5f0444abe81e8a460eec980788140) (via search snippet)
- Spark reportedly moved $150M of stablecoin liquidity to a Uniswap v4 "DualPool" hook (2026). — [TechFlow](https://techflowpost.com/en-US/article/33939) (via search snippet)
- DepegShield, SentinelPeg and AnchorHook are hackathon/testnet depeg-protection hooks, mostly "raise fees during depeg" designs. — [ETHGlobal AnchorHook](https://ethglobal.com/showcase/anchorhookv4-mes8e); [DepegShield](https://vat.pages.dev/Aman035/depegShield) (via search snippets)

### Inferences
- Section order across the readable sites is consistently: superlative hero → capability/product cards → stat tiles → "build/integrate" → trust (audits/transparency) → blog/community → newsletter. Mento shows this fully. Fluid and Curve compress it to nearly nothing and rely on brand recognition.
- Mature brands (Curve, Fluid) can afford a near-empty landing. A new entrant like Fermi cannot, so a Mento-style structured page with explicit proof blocks is the more relevant template.
- The hero copy of the general AMMs (Balancer, Ekubo, Fluid) competes on "capital efficiency" and "programmability". None of the readable heroes competes on LP safety.

### Gaps
- Exact live hero copy for curve.finance, balancer.fi, ekubo.org and mav.xyz: blocked, rate-limited or JS-only. A manual browser visit is needed to confirm.
- Frax/Fraxswap: not researched within the tool budget. Fraxswap is a TWAMM constant-product AMM rather than a StableSwap, so it is less relevant. Frax's Curve-pool-based stable strategy was also not checked.
- Saddle (historical): Wayback Machine was unreachable, so no verbatim copy was gathered. Saddle shut down in 2023 (prior knowledge, not re-verified here).
- Visual identity details (fonts, palettes) beyond Curve's rendered splash were not captured.

## Q2: How do they communicate risk, depeg protection, or safety?

### Takeaway
Almost none of them mention depeg risk on the landing surface. Safety is signalled indirectly through audit lists, bug-bounty and "Transparency/Risk Research" footer links, collateralization ratios (Mento) or "on-chain verifiable reserves". No incumbent states a quantified bound on LP loss when a pool asset fails.

### Cited Findings
- Fluid pushes risk to footer links ("Bug Bounty", "Transparency", "Risk Research"). The hero has no risk language. — [fluid.io](https://fluid.io/)
- Mento frames safety as reserve transparency and over-collateralization: "All Mento Reserve assets are visible onchain, ensuring complete verification". Its infrastructure is "designed for resilience against centralized points of failure". It shows a "3:1" collateralization tile. The page has no explicit risk disclosure. — [mento.org](https://www.mento.org/)
- Curve's user intro has no depeg or imbalanced-pool language. Its only risk statement concerns LLAMMA liquidations ("conversions incur losses and can still end in full liquidation"). — [Curve user intro](https://docs.curve.finance/user/introduction)
- Balancer's Stable Pool doc has no depeg or risk warnings. It lists only ideal use cases (pegged tokens that "swap near 1:1"). — [Balancer Stable Pool docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/stable-pool/stable-pool.html)
- PancakeSwap StableSwap docs have no depeg warnings. — [PancakeSwap docs](https://docs.pancake.xyz/trade/stableswap)
- Uniswap StablePair launch coverage has no depeg/risk language. — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Independent analysts document the real risk. During the March 2023 USDC depeg, Curve slippage rose above 3% "as the pool became heavily imbalanced". For Balancer, the main risk is described as a sustained depeg of one asset. Uniswap v3 out-of-range stable LPs become entirely the weaker asset. — [Spark comparison](https://www.spark.money/tools/stablecoin-automated-market-maker-comparison)
- Depeg-protection messaging exists only among hackathon/forum projects, and it usually describes dynamic or emergency fees. A Stabilizer forum post claims its emergency fee removes LP losses, but this is a proposal and unverified. — [Stabilizer forum](https://stabilizer.discourse.group/t/stabilizer-risk-framework-onboarding-new-stablecoins/181) (via search snippet)

### Inferences
- The silence is structural. A StableSwap pool's failure mode is that LPs end up holding the failed coin, which is bad marketing, so incumbents leave it out. That leaves "what happens to my LP position when one stablecoin fails" unclaimed on every major landing page.
- Existing "depeg protection" messaging, in hooks and forums, is about fees: compensating LPs or discouraging toxic flow. None of it offers a provable cap on loss. A bounded-loss guarantee with a stated number would be categorically different from both incumbents and v4 competitors.

### Gaps
- Whether curve.finance or balancer.fi show risk disclaimers inside the app (e.g., pool-page warnings) could not be checked because the SPAs did not render.

## Q3: How do they explain their invariant/curve to non-experts vs experts?

### Takeaway
Landing pages and user docs explain the mechanism with outcome words only ("lower slippage", "near parity", "capital-efficient") and avoid formulas. Formulas live in the whitepaper or developer docs. The best plain-language explanation found is Uniswap's StablePair description, which narrates fee behaviour in three short cases.

### Cited Findings
- PancakeSwap: "lower slippage based on an invariant curve". That is the entire explanation, with no diagram or formula. — [PancakeSwap docs](https://docs.pancake.xyz/trade/stableswap)
- Balancer: "Stable Math (based on StableSwap, popularized by Curve)" lets large swaps occur "before encountering substantial price impact". The page gives no formula and does not mention amplification. — [Balancer Stable Pool docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/stable-pool/stable-pool.html)
- Curve user docs never name StableSwap or show an invariant. — [Curve user intro](https://docs.curve.finance/user/introduction)
- Analyst-level explanation: Curve is "a hybrid of constant-sum and constant-product curves", with an amplification coefficient A keeping the curve flat near the peg and shifting toward constant-product as pools skew. Velodrome/Aerodrome use x³y + xy³ = k. — [Spark comparison](https://www.spark.money/tools/stablecoin-automated-market-maker-comparison)
- Uniswap StablePair uses a case-based plain-language explanation: near the peg there is a fixed spread, trades moving away "pay no fee", and trades moving back face a falling Dutch-auction fee. — [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)
- Ekubo explains by feature list ("concentrated liquidity, extensibility, and low fees"), not by curve. — [ekubo.org (via search)](https://ekubo.org)

### Inferences
- The common two-tier pattern is: benefit-only sentence on the landing page → feature cards → "Technical Docs"/whitepaper link for the math. No landing page shows an interactive curve or a depeg simulation. An interactive "one coin goes to zero, here is your max loss" visual would be novel.
- The Uniswap StablePair "three cases" structure is a good template for explaining Fermi's mechanism in plain language before showing the formal bound.

### Gaps
- Curve's visual explainer assets (e.g., the classic StableSwap vs constant-product curve chart in the whitepaper) were not re-verified on current pages.

## Q4: What patterns are common, and what is notably absent (gaps Fermi could own)?

### Takeaway
Common elements are a superlative one-line hero, capital-efficiency or "liquidity layer" claims, stat tiles (volume, users, pools, integrations), audit-logo rows, and "Launch App" as primary CTA with "Docs/Integrate/Build" as secondary. Absent everywhere: explicit, quantified LP downside protection, honest depeg-scenario explanation, and a direct comparison against Curve in the hero.

### Cited Findings
- Superlative/category headlines: "The Liquidity Layer For All Finance" ([Fluid](https://fluid.io/)), "The most advanced AMM ever" ([Ekubo](https://ekubo.org)), "AMMs made easy" ([Balancer docs](https://docs.balancer.fi/)), "The Future Of Onchain FX" ([Mento](https://www.mento.org/)).
- Stat-tile proof: Mento shows users, volume, transactions, number of stablecoins and collateral ratio ([mento.org](https://www.mento.org/)). The Balancer mirror shows pools, 24h volume and aggregator integrations ([unofficial mirror](https://balancer-com.pages.dev)). Uniswap's launch uses ecosystem-level volume and hook counts ([The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160)).
- Audit/trust blocks: Mento lists named auditors with dates ([mento.org](https://www.mento.org/)). Fluid relies on footer "Bug Bounty / Transparency / Risk Research" links ([fluid.io](https://fluid.io/)).
- Competitors reference Curve as the benchmark in docs ("popularized by Curve") but not on landing pages. — [Balancer Stable Pool docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/stable-pool/stable-pool.html); [The Block](https://theblock.co/news/defi/2026-09-10-uniswap-stablepair-hook-414160) has no Curve mention.
- Balancer caps Stable Pools at a "safe maximum of 5 tokens, due to the constraints of Stable Math", which hints that multi-asset stable baskets have acknowledged limits. — [Balancer Stable Pool docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/stable-pool/stable-pool.html)

### Inferences
- Gaps Fermi could own:
  1. A hero built on LP safety rather than efficiency, e.g., stating the provable max loss when one stablecoin fails as a number.
  2. A "what happens in a depeg" section with a worked scenario or interactive simulator. Nobody shows one.
  3. An explicit "vs Curve StableSwap" comparison, which incumbents avoid on landing pages.
  4. Proof blocks centred on verification (formal bound, invariant tests, audit) rather than TVL, which a hackathon-stage project cannot show anyway.
  5. Multi-stablecoin baskets framed as diversification with bounded tail risk. Uniswap StablePair is pair-only and Balancer flags a 5-token stable limit.
- Tone norm: confident, terse, superlative, and largely risk-silent. A calmer, precise, "engineering-honest" voice that names the risk and then bounds it would stand out, especially after StablePair flaw reports and the 2023 USDC depeg imbalance at Curve.
- Visual norm (limited evidence): Curve uses a light warm-grey background, a bold black sans wordmark and a saturated rainbow 3D mark ([observed render](https://www.curve.finance/)). Other palettes were not captured.

### Gaps
- No systematic capture of fonts, color palettes or imagery for Balancer, Fluid, Ekubo, Maverick or Mento.
- Live current hero copy for Curve, Balancer, Ekubo and Maverick still needs manual confirmation.
- Frax/Fraxswap and Saddle were not covered (see Q1 gaps).
