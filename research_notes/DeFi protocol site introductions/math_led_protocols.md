# How Math-Led DeFi Protocols Introduce Themselves and Present Their Papers

Scope: Primitive, Panoptic, Ajna, Morpho (Blue), Euler v2, Ethena, crvUSD/LLAMMA, Uniswap v3, Balancer, Sommelier, Gyroscope, Angle, Liquity v2, and Paradigm research posts. Homepages were fetched in Nov 2026 (current live versions). Some fetches failed: primitive.xyz returned HTTP 402, Wayback was blocked, Curve docs returned 404/403, and paper.panoptic.xyz / intro.panoptic.xyz returned only their titles (JS-rendered). Those gaps are noted.

## Q1. Where does the math appear, and how are papers surfaced?

### Takeaway
Almost none of these protocols put math in the homepage hero. The hero sells an outcome ("Borrow on your terms", "Superliquidity, made simple", "Permissionless Lending Pools"). The math sits one or two clicks away: in a PDF whitepaper linked from a nav or footer "Learn/Resources" group, in docs pages that render the invariant with variable definitions, or in a separate subdomain reader (Panoptic's paper.panoptic.xyz). Papers are surfaced as PDFs (often dated in the filename or labeled with a revision), GitBook web readers, GitHub-hosted PDFs, or arXiv preprints.

### Cited Findings
**Gyroscope**
- Hero: "Superliquidity, made simple." Problem framing: "DeFi has a problem: optimal liquidity provision is hard." The homepage has no formulas, no E-CLP mention and no whitepaper link. Sections run: Volatile Pairs, Stable Pairs, GYD, "Want to passively LP?", "GYD is superliquid.", "The swap-fee machine is now live.", Supporters, Auditors, Community, Resources, About. — [gyro.finance](https://www.gyro.finance/)
- The docs landing ("Start here to learn more about Gyroscope.") is just cards (Docs, Audits, Pools, Governance, GYD "The Gyro Dollar", Deployments) and has no math. — [docs.gyro.finance](https://docs.gyro.finance/)
- The E-CLP math sits in GitBook pages and a technical-papers repo. Secondary sources cite an "E-CLP Mathematics.pdf" in the gyrostable technical-papers GitHub repo (not verified directly). The GitBook says E-CLPs "will be used for stablecoin pools that include ... GYD". — [Gyroscope GitBook E-CLPs](https://gyroscope.gitbook.io/gyroscope-protocol/concentrated-liquidity-pools/e-clps); [secondary notes](https://gitea.jeffemmett.com/jeffemmett/myco-bonding-curve/src/branch/dev/docs/04-elliptical-clp.md)
- The E-CLP math is also documented on Balancer's docs as a pool type. — [Balancer docs: Gyro E-CLP](https://docs.balancer.fi/concepts/explore-available-balancer-pools/gyroscope-pool/gyro-eclp.html)

**Ajna**
- Hero: "Permissionless Lending Pools". Sub: "a noncustodial, peer-to-pool, permissionless lending, borrowing and trading system that requires no governance or external price feeds to function." Banner: "No permission | No governance | No PRICE FEEDS". — [ajna.finance](https://www.ajna.finance/)
- Whitepaper: a PDF behind a "Read" button, with the date in the filename (`/pdf/Ajna_Protocol_Whitepaper_01-11-2024.pdf`). There is also a separate `/whitepaper` page and an **ELI5 PDF** (`/pdf/Ajna_ELI5.pdf`). — [ajna.finance](https://www.ajna.finance/)

**Panoptic**
- Hero: "Trade volatility. Earn more from your liquidity." Sub: "Panoptic is a perpetual options protocol built on Uniswap that enables oracle-free options trading on any token". The first section heading reframes the math as an identity: "Your AMM liquidity is the option." The differentiator section: "No order books. No oracles. No expiries." — [panoptic.xyz](https://panoptic.xyz/)
- Papers get their own subdomains under "Learn": a whitepaper at paper.panoptic.xyz and a litepaper at intro.panoptic.xyz. Both are JS-rendered; the fetch returned only the titles "Panoptic Whitepaper" and "Panoptic Litepaper". — [paper.panoptic.xyz](https://paper.panoptic.xyz/); [intro.panoptic.xyz](https://intro.panoptic.xyz/)
- The homepage also promotes a research article titled "Your Uniswap LP Is a Short Option (Interactive Charts)", which shows "how loans, put spreads, and selling options hedge impermanent loss." — [panoptic.xyz](https://panoptic.xyz/)

**Primitive (RMM-01)**
- The math is published as arXiv preprints. The foundation is "Replicating Market Makers" by Angeris, Evans and Chitra (arXiv:2103.14769, 2021). Follow-ups are "Replicating Portfolios: Constructing Permissionless Derivatives" by Sterrett, Jepsen and Kim (arXiv:2205.09890, 2022) and "Analysis of the RMM-01 Market Maker" by Jepsen and Roberts (arXiv:2310.14320, Oct 2023). The Primitive whitepaper is credited to Sterrett, Angel and Czernik. A public `rmm01-simulations` repo also exists. — [arXiv 2310.14320](https://arxiv.org/pdf/2310.14320); [ar5iv 2205.09890](https://ar5iv.labs.arxiv.org/html/2205.09890); [arXiv 2103.14769 mirror](https://arxiv.deeppaper.ai/papers/2103.14769v1); [rmm01-simulations](https://awesome.ecosyste.ms/projects/github.com%2Fprimitivefinance%2Frmm01-simulations)
- The current homepage could not be retrieved (HTTP 402). — [primitive.xyz](https://www.primitive.xyz/)

**Morpho**
- Hero: "Open infrastructure for global credit". The homepage links no whitepaper. Minimalism is framed as a design value: "Open by default, minimal by design." — [morpho.org](https://morpho.org/)
- The Morpho Blue whitepaper is a PDF at the GitHub repo root (`morpho-blue-whitepaper.pdf`). The repo also has a top-level `certora` folder (formal-verification specs), and "All audits are stored in the audits folder." — [github.com/morpho-org/morpho-blue](https://github.com/morpho-org/morpho-blue)

**Euler v2**
- Hero: "The credit layer for programmable finance." Papers are split by component and listed as a set: Lite Paper, EVK White Paper, EVC White Paper, v1 Redeemer, and MiCA Whitepaper (PDF). — [euler.finance](https://www.euler.finance/)

**Liquity v2**
- Hero: "Borrow on your terms". Sub: "The immutable and decentralized way to borrow against ETH & staked ETH". The footer "Whitepaper" link goes to a GitBook web reader (liquity.gitbook.io/v2-whitepaper). Earlier nav linked an IPFS PDF labeled "Liquity v2 - Whitepaper rev. 0.3 (November, 2024)". — [liquity.org](https://www.liquity.org/)

**Curve crvUSD / LLAMMA**
- The whitepaper was released Nov 22, 2022, announced via Substack, and hosted as a PDF in GitHub (`curvefi/curve-stablecoin/doc/curve-stablecoin.pdf`, path per secondary sources). It introduced the "lending-liquidating AMM algorithm" (LLAMMA). — [Curve Substack](https://curve.substack.com/p/november-22-2022-crvusd-white-paper); [The Block](https://www.theblock.co/post/189140/curve-releases-whitepaper-and-official-code-for-its-stablecoin)
- Curve docs say "losses through soft- and de-liquidation only occur when the loan is in liquidation mode" (via search snippet; docs pages returned 404/403 on fetch). — [docs.curve.finance overview](https://docs.curve.finance/docs/developer/crvusd/overview.md); [resources.curve.fi loan concepts](https://resources.curve.fi/crvusd/loan-concepts)

**Uniswap v3**
- The launch blog sells the math as a ratio: "the most flexible and efficient AMM ever designed" and "up to 4000x capital efficiency" compared with v2. Depth is deferred: readers are pointed to the "Uniswap v3 Core whitepaper" (a PDF). — [blog.uniswap.org/uniswap-v3](https://blog.uniswap.org/uniswap-v3)

**Balancer weighted math (docs pattern)**
- The page structure is Overview, then Implementations (TypeScript, Python), then Invariant, Spot Price, and Swap Equations (outGivenIn / inGivenOut). Each displayed formula is followed by bulleted variable definitions, and an "Info" callout covers fees. Framing: "Weighted Math is designed to allow for swaps between any assets whether or not they have any price correlation" and it "is a generalization of the constant product formula". Derivations are deferred: "For more formulas and derivations of the below formulas, please refer to the Balancer Whitepaper" (`/whitepaper.pdf`). — [Balancer Weighted Math](https://docs.balancer.fi/concepts/explore-available-balancer-pools/weighted-pool/weighted-math.html)

**Paradigm research posts**
- "Uniswap v3: The Universal AMM" by Dan Robinson (06.07.2021) opens with a plain sentence ("Uniswap v3 allows liquidity providers to provide custom amounts of liquidity in selected price ranges.") and then states a striking claim: any static AMM can be approximated with v3 positions. The body is built around trading functions and invariants, with figures ("liquidity fingerprints" for v2, Curve, Balancer and LMSR) and derivations moved to appendices (A: liquidity definition, B: LMSR example). It ends with an honest "Future work" list of limitations. Footer: "This post is for general information purposes only." It adds that the post is not investment advice and the views are the author's. — [paradigm.xyz](https://www.paradigm.xyz/2021/06/uniswap-v3-the-universal-amm)

**Ethena, Sommelier, Angle (non-math-hero examples)**
- Ethena: "Digital Dollars for the Internet Economy". No whitepaper link on the homepage, and docs go to docs.ethena.fi. "Delta-neutral" is not mentioned on the homepage. — [ethena.fi](https://ethena.fi/)
- Sommelier: "Most battle-tested infrastructure in DeFi" / "Not a vault UI, a protocol logic layer". No whitepaper link. — [somm.finance](https://www.somm.finance/)
- Angle: the homepage leads with "Angle is entering its final chapter." and "every USDA and EURA is redeemable 1:1." It sets a redemption deadline of March 1, 2027. — [angle.money](https://www.angle.money/)

### Inferences
- The dominant pattern has three layers. (1) The hero states the outcome in plain words. (2) A short "how it works" or differentiator line expresses the math as an identity or a negation ("Your AMM liquidity is the option"; "No oracles. No expiries."). (3) The paper (PDF, GitBook or subdomain reader) plus docs pages give the formula followed by variable definitions.
- Labeling the paper with a revision or date (Ajna's dated filename, Liquity's "rev. 0.3 (November, 2024)") is a common credibility and versioning signal that Fermi could copy ("Yellow Paper v1.0 — date").
- Offering two depths of paper is common: Panoptic (litepaper and whitepaper), Ajna (ELI5 and whitepaper), Euler (Lite Paper and white papers per component).
- For math credibility, arXiv preprints (the Primitive ecosystem) carry academic weight that a PDF on the site alone does not.

### Gaps
- The live Primitive homepage could not be fetched (402), and Wayback was blocked. Its current hero copy is unknown.
- The Panoptic paper reader's format (TOC, LaTeX rendering, download button) could not be observed because the pages are JS-rendered.
- The Gyroscope E-CLP paper's PDF location was not verified directly.
- The text of the crvUSD whitepaper PDF and the Curve docs pages could not be fetched.

## Q2. How are theorems or guarantees turned into headlines without overclaiming, and what disclaimers come with them?

### Takeaway
Headline guarantees are almost always structural negations: no oracles, no governance, no expiry, immutable, no off-chain collateral. These are verifiably true of the code. Economic outcomes (losses, yields) get hedged, quantified ratios ("up to 4000x"), or are omitted from the hero. Risk language lives in the footer (Risk Disclosures, Protocol Disclaimer), in FAQ entries, or at the end of research posts. Explicit "no loss" claims are absent. Curve's own docs scope losses ("only occur when the loan is in liquidation mode") rather than deny them.

### Cited Findings
- Ajna's structural negations: "No permission | No governance | No PRICE FEEDS". Its commitment claim: "Ajna is fully automated. Once it's launched, the team will move on and cease to update or maintain the protocol." Disclaimer on third-party apps: "these apps are built and maintained by third parties". — [ajna.finance](https://www.ajna.finance/)
- Panoptic: "Options have no expiry because there is no contract to expire." and "Prices come from Uniswap liquidity itself rather than an external feed". The homepage makes no liquidation claim. Its disclaimers read "The content provided is for informational and educational purposes only..." and "Options trading carries significant risks, including the potential for substantial losses". The only quantified economic claim ("earn 20%+ more fees") is in the FAQ, not the hero. — [panoptic.xyz](https://panoptic.xyz/)
- Liquity v2: "Liquity V2 cannot be changed or upgraded." / "No governance or admins" / "No off-chain collateral backing". It cites an outside credibility anchor ("rated A- by Bluechip") and a hedged risk statement ("BOLD is a USD stablecoin with a differentiated risk profile"). The footer links to a "Protocol Disclaimer" and "Website Terms". The frontend disclaimer reads "Liquity does not run its own Frontend." / "DYOR!". Coverage is mentioned as "Coverage coming soon," "Powered by Nexus Mutual." — [liquity.org](https://www.liquity.org/)
- Uniswap v3 states the downside next to the headline benefit. Concentrating liquidity means "taking on more price risk" ("impermanent loss"), and out-of-range liquidity "is effectively removed from the pool and is no longer earning fees." It also says "we cannot guarantee all bugs have already been discovered and resolved." — [blog.uniswap.org](https://blog.uniswap.org/uniswap-v3)
- Curve LLAMMA: losses are scoped by condition: "losses through soft- and de-liquidation only occur when the loan is in liquidation mode." — [Curve docs (search snippet)](https://docs.curve.finance/docs/developer/crvusd/overview.md)
- Ethena attaches a methodology note to its yield number: "sUSDe APY data is an average from January 1st 2024 to the present which is based upon weekly data reported by Ethena." The homepage has no risk disclosure. — [ethena.fi](https://ethena.fi/)
- Euler: footer links only (Terms of Use, Privacy Policy, Risk Disclosures). — [euler.finance](https://www.euler.finance/)
- Paradigm: "This post is for general information purposes only... not investment, legal, tax, or accounting advice". The research post itself ends with limitations ("Future work"). — [paradigm.xyz](https://www.paradigm.xyz/2021/06/uniswap-v3-the-universal-amm)

### Inferences
- For Fermi's "bounded LP loss from any failed coin" theorem, the safe pattern from these examples is to state it as a conditional, quantified bound with the parameter visible. Example: "If any one coin goes to zero, LP loss is capped at X% (Theorem N, Yellow Paper §k)". Avoid "no loss" or "safe" language. Put the assumptions next to the claim, the way Uniswap paired "4000x" with "more price risk" and Curve scoped losses to "liquidation mode".
- Link every headline guarantee to a specific theorem or section anchor in the paper. No protocol observed does this on its homepage, so it would be a differentiator. That is an inference, not something observed.
- Pair the claim with an "options trading carries significant risks" style disclaimer and a footer Risk Disclosures page (Panoptic, Euler, Liquity pattern).

### Gaps
- No observed homepage links a headline claim to a numbered theorem. I could not confirm whether any protocol does this.
- I did not retrieve the full text of any protocol's legal Risk Disclosures page.

## Q3. Credibility signals and tone

### Takeaway
Credibility is signaled through counts and logos rather than prose: audit-firm logo walls, audit and engagement counts, bug bounty sizes, "formally verified" statements naming Certora or Runtime Verification, investor logos, and third-party ratings. Tone is confident and terse, with short declaratives and negations. Research posts take a more academic tone with a named author.

### Cited Findings
- Morpho: "30+ audits to date", "Built to be formally verified", "Every line of code is fully auditable, immutable, and verifiable." — [morpho.org](https://morpho.org/)
- Euler: "60+ independent security engagements"; "Certora has formally verified properties of Euler V2 core and EulerEarn"; bug bounty "of up to $7.5m". Note the inconsistency: a stats block appears to show 100 engagements against "60+" in the text. — [euler.finance](https://www.euler.finance/)
- Panoptic lists audit statuses (Obsidian, Nethermind and Code4rena, each "Complete") plus "Multiple independent security audits, formal verification, and a competitive audit program." Section heading: "Trust the code, not the counterparty." Backers section: "Institutional conviction." — [panoptic.xyz](https://panoptic.xyz/)
- Gyroscope: an "Auditors" logo wall (Nethermind, Runtime Verification, Trail of Bits) with no descriptive text. — [gyro.finance](https://www.gyro.finance/)
- Liquity: "Audited and secured by" ChainSecurity, Dedaub, Chaos Labs, Hats Finance, Certora, Coinspect and Recon. Uses a Bluechip rating. — [liquity.org](https://www.liquity.org/)
- Uniswap v3: Trail of Bits and ABDK audits, a samczsun review, and Echidna/Manticore fuzzing. Also cites a BUSL 1.1 license. — [blog.uniswap.org](https://blog.uniswap.org/uniswap-v3)
- Ethena: SOC 2 Type II, "with zero exceptions noted"; "Independent verification of the allocation and value of backing assets held with custodians"; a live "Protocol Backing Ratio". — [ethena.fi](https://ethena.fi/)
- Sommelier: "All smart contracts have been independently audited and Somm has an active bug bounty program."; "Vault logic is fully visible — every action is verifiable and on chain." — [somm.finance](https://www.somm.finance/)
- Ajna: "Ajna has code audits from industry leading agencies with verified reports." — [ajna.finance](https://www.ajna.finance/)
- Morpho Blue repo: `certora` folder, `audits` folder, and licenses (GPL-2.0-or-later for `Morpho.sol`, MIT otherwise). — [GitHub](https://github.com/morpho-org/morpho-blue)
- Academic credibility: named authors on arXiv (Angeris, Evans, Chitra; Jepsen; Sterrett). — [arXiv 2310.14320](https://arxiv.org/pdf/2310.14320)

### Inferences
- For a hackathon-stage protocol without audits, the equivalents are: named authors on the yellow paper; a public invariant and fuzz test suite (as Uniswap cited Echidna); simulations in a repo (as Primitive did with `rmm01-simulations`); and machine-checked or tested properties, honestly labeled ("tested", not "audited").
- Avoid inconsistent counts like Euler's 60+ versus 100.

### Gaps
- No observed homepage lists the yellow paper's authors in the hero. Author presentation inside the PDFs was not checked.

## Q4. Interactive simulators and calculators; what good paper reader pages look like

### Takeaway
Interactive math is rare on homepages. The strongest example found is Panoptic's research article "Your Uniswap LP Is a Short Option (Interactive Charts)", promoted from the homepage. Paradigm uses static figures with zoom, plus appendices. Primitive published simulations as code. Paper "landing pages" are mostly a PDF link or a GitBook. Good readers offer a version or date, a lite or ELI5 companion, and formula pages with variable definitions and reference implementations (the Balancer docs model).

### Cited Findings
- Panoptic: "Your Uniswap LP Is a Short Option (Interactive Charts)", showing "how loans, put spreads, and selling options hedge impermanent loss." — [panoptic.xyz](https://panoptic.xyz/)
- Paradigm: static figures (reserve curves, "liquidity fingerprint" graphs) with zoom, plus a "Listen" audio option and Markdown/X/LinkedIn share links. The article body is static. Derivations go in appendices. — [paradigm.xyz](https://www.paradigm.xyz/2021/06/uniswap-v3-the-universal-amm)
- Primitive: open-source RMM-01 simulations repo. — [rmm01-simulations](https://awesome.ecosyste.ms/projects/github.com%2Fprimitivefinance%2Frmm01-simulations)
- Balancer: formula, then variable bullets, then a fee caveat callout, then reference code in TypeScript and Python, with the whitepaper PDF for derivations. — [Balancer docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/weighted-pool/weighted-math.html)
- Ajna: whitepaper PDF ("Read" button, dated filename), an ELI5 PDF, and a /whitepaper page. — [ajna.finance](https://www.ajna.finance/)
- Liquity: GitBook web reader plus a versioned IPFS PDF ("rev. 0.3 (November, 2024)"). — [liquity.org](https://www.liquity.org/)
- Panoptic: dedicated paper subdomains (paper., intro.). — [panoptic.xyz](https://panoptic.xyz/)

### Inferences
- A strong Fermi yellow paper page would combine:
  - a title, version and date, and authors
  - a one-paragraph abstract
  - the headline theorem shown as a boxed statement with its assumptions
  - an interactive "fail a coin" simulator showing LP loss against the bound
  - a PDF download, plus an in-page TOC or web reader
  - a citation block or arXiv link
  - a link to the tests and simulations repo
- No protocol observed combines all of these, so doing so would be distinctive. This is an inference.

### Gaps
- No live calculator was found on any homepage in scope.
- The layout of the Panoptic paper reader and Gyroscope's technical-papers presentation could not be observed.
- Ethereum's Yellow Paper and other canonical "yellow paper" readers were not examined because of the tool-call budget.
