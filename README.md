# ArcKit

The canonical SDK, hook templates, and scaffold for building agent commerce on [Arc](https://arc.network).

ArcKit fills the gap between Arc's [App Kit](https://docs.arc.network/app-kit) (which covers Bridge / Swap / Send for USDC) and the agent commerce primitives Arc devs actually need to ship.

## What's inside

| Package | Description |
|---|---|
| [`arckit-sdk`](./packages/sdk) | TypeScript SDK — typed clients for ERC-8183 (AgenticCommerce), ERC-8004 (Identity / Reputation / Validation), and USDC payment flows |
| [`arckit-sdk`](./packages/sdk-py) | Python SDK — same surface as the TS client, AI/agent-builder friendly |
| [`@arckit/hooks`](./packages/hooks) | Five production-grade `IACPHook` Solidity templates: MultiEvaluator, Milestone, TimeDecayReputation, Escalation, MultiStablecoin |
| [`create-arc-app`](./packages/create-arc-app) | `npx create-arc-app` — scaffold a working ERC-8183 client + provider + evaluator triad on Arc testnet in one command |

## Quick start

### TypeScript

```bash
npm install arckit-sdk viem
```

```ts
import { ArcKit } from 'arckit-sdk';
import { privateKeyToAccount } from 'viem/accounts';

const arc = new ArcKit({
  account: privateKeyToAccount('0x...'),
  network: 'testnet',
});

const jobId = await arc.commerce.createJob({
  provider: '0x...',
  evaluator: '0x...',
  expiredAt: Math.floor(Date.now() / 1000) + 86400,
  description: 'Audit my Solidity contract',
  hook: '0x0000000000000000000000000000000000000000',
});
```

### Python

```bash
pip install arckit-sdk
```

```python
from arckit import ArcKit

arc = ArcKit(private_key="0x...", network="testnet")

job_id = arc.commerce.create_job(
    provider="0x...",
    evaluator="0x...",
    expired_at_hours=24,
    description="Audit my Solidity contract",
)
```

### Scaffold

```bash
npx create-arc-app my-agent-app
cd my-agent-app
pnpm dev
```

## Arc contracts

ArcKit wraps the canonical Arc testnet contracts:

| Contract | Address |
|---|---|
| AgenticCommerce (ERC-8183) | `0x0747EEf0706327138c69792bF28Cd525089e4583` |
| IdentityRegistry (ERC-8004) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` |
| ReputationRegistry (ERC-8004) | `0x8004B663056A597Dffe9eCcC1965A193B7388713` |
| ValidationRegistry (ERC-8004) | `0x8004Cb1BF31DAf7788923b405b754f57acEB4272` |
| USDC | `0x3600000000000000000000000000000000000000` |

## Status

Pre-release. v0.1 ships these packages with working tests against Arc testnet.

## License

MIT
