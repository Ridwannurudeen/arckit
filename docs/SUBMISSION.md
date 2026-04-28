# Arc Builders Fund — ArcKit submission draft

**Status:** DRAFT — awaiting user approval before submitting.

This document holds the canonical submission text for the Arc Builders Fund (agentic commerce track) and the X / community-forum announcements that ship alongside the v0.1 release.

## Application: Arc Builders Fund

**Project:** ArcKit
**Vertical:** Agentic Commerce
**Repo:** https://github.com/Ridwannurudeen/arckit
**License:** MIT
**Status:** v0.1 — built, tested, ready to publish

### What it is

The canonical SDK, hook templates, and scaffold for building agent commerce on Arc. Fills the gap between Arc's [App Kit](https://docs.arc.network/app-kit) (Bridge / Swap / Send) and the agent commerce primitives Arc devs need to ship — namely typed clients for ERC-8183 (AgenticCommerce), ERC-8004 (Identity / Reputation / Validation), USDC payment flows, plus reusable `IACPHook` templates and a one-command project scaffold.

### Why it fits the "primitives others compose with" mandate

Arc's current developer experience for ERC-8183 requires hand-rolling raw ABI calls against the canonical contract at `0x0747EEf0706327138c69792bF28Cd525089e4583`. Every published Arc sample app (`circlefin/arc-escrow`, `arc-commerce`, `arc-nanopayments`, etc.) re-implements the same approve / fund / poll boilerplate inline. ArcKit extracts that boilerplate into one canonical, type-safe surface.

The hook layer is even more underbuilt: Arc tutorials hardcode `hook: address(0)` because no template library exists. ArcKit ships five production templates (MultiEvaluator, Milestone, TimeDecayReputation, Escalation, MultiStablecoin) covering the common gating patterns Arc devs are asked about in community forums.

### What's shipped at v0.1

| Package | LOC | Tests |
|---|---|---|
| `arckit-sdk` (TypeScript, viem) | ~600 LOC | 21 vitest |
| `arckit-sdk` (Python, web3.py) | ~700 LOC | 25 pytest |
| `@arckit/hooks` (5 Solidity contracts + base) | ~600 LOC | 45 forge |
| `create-arckit-app` (CLI scaffold) | ~150 LOC | 5 vitest |
| `examples/` (Python lifecycle, LangChain tool) | ~250 LOC | – |

**96 tests passing.** All packages build cleanly. CI configured for npm + PyPI auto-publish on tagged releases.

### Why now

Arc mainnet beta + token launch announced (Allaire, Apr 14 2026 in Seoul). HackMoney 2026 Arc Track winners (arctan, Text-to-Chain, ArcFlow, Versus) shipped agentic commerce **applications** but none extracted a reusable SDK. BNB Chain shipped the first live ERC-8183 SDK before Arc did — the Arc-native canonical SDK position is open.

### What I'm asking for

Recognition or grant funding to:
1. Maintain ArcKit through the mainnet launch (continued canonical address tracking, mainnet contract additions, security audits)
2. Add a reference indexer + dashboard (out of v0.1 scope) once mainnet adoption justifies it
3. Run an on-chain devrel sprint — workshops, guides, and forum support tied to the Architect program

### Why me

- Already shipped on Arc: [arc-agent-commerce](https://github.com/Ridwannurudeen/arc-agent-commerce) (Arc testnet) — multi-stage pipeline orchestrator with PipelineOrchestrator, CommerceHook, AgentPolicy. Pipeline #0 completed on-chain. Agent IDs 933 (client) + 1149 (provider) live on ERC-8004.
- Bug bounty contributor on `circlefin/arc-node` — 5 HackerOne reports submitted in the program window
- Running an Arc RPC follower node on Servarica VPS

### Verification

- All code: https://github.com/Ridwannurudeen/arckit (public, MIT)
- npm packs verified: `arckit-sdk` (40KB), `create-arckit-app` (4.7KB)
- PyPI build verified: `arckit-0.1.0-py3-none-any.whl` (16KB)
- CI workflow: `.github/workflows/ci.yml` (TS + Python + Solidity matrix)
- Release workflow: `.github/workflows/publish.yml` (tag-driven)

---

## Forum / X announcement (v0.1 launch)

> Just shipped **ArcKit** — the canonical SDK, hook templates, and scaffold for building agent commerce on Arc.
>
> @arc/sdk doesn't exist yet. App Kit covers Bridge/Swap/Send. ArcKit covers the rest — typed clients for ERC-8183 jobs, ERC-8004 identity & reputation, USDC payments, plus 5 production-ready `IACPHook` templates (multi-evaluator, milestone, escalation, time-decay reputation, multi-stablecoin).
>
> ```bash
> npx create-arckit-app my-agent
> npm install arckit-sdk
> pip install arckit-sdk
> ```
>
> Both TypeScript and Python parity. MIT-licensed. 96 tests passing.
>
> Built because hand-rolling ABIs against the canonical AgenticCommerce contract was not the developer experience Arc deserves. Open to feedback, PRs, and adoption signals.
>
> Repo: https://github.com/Ridwannurudeen/arckit

## Pre-submission checklist (USER MUST APPROVE EACH)

- [ ] User reviews this submission draft
- [ ] User reviews repo state on GitHub (push happens after user approval)
- [ ] User decides: submit to Arc Builders Fund, post to forum, post to X — yes/no for each channel
- [ ] User provides any required forms (Builders Fund application URL, application format)
- [ ] After approval: I run the publish workflow + post the announcements
