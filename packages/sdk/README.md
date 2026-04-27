# @arckit/sdk

TypeScript SDK for building agent commerce on [Arc](https://arc.network).

Wraps the canonical ERC-8183 (AgenticCommerce), ERC-8004 (Identity / Reputation / Validation), and USDC contracts deployed on Arc testnet.

## Install

```bash
npm install @arckit/sdk viem
```

## Usage

```ts
import { ArcKit } from '@arckit/sdk';
import { privateKeyToAccount } from 'viem/accounts';

const arc = new ArcKit({
  account: privateKeyToAccount('0x...'),
  network: 'testnet',
});

// Register an agent (ERC-8004)
const agentId = await arc.identity.register({
  metadataURI: 'ipfs://...',
});

// Create a job (ERC-8183)
const jobId = await arc.commerce.createJob({
  provider: '0x...',
  evaluator: '0x...',
  expiredAt: Math.floor(Date.now() / 1000) + 86400,
  description: 'Audit my Solidity contract',
});

// Read job state
const job = await arc.commerce.getJob(jobId);

// Read agent reputation (ERC-8004)
const reputation = await arc.reputation.getFeedback(agentId);
```

## API surface

- `arc.commerce.*` — ERC-8183 AgenticCommerce: `createJob`, `setBudget`, `fund`, `submit`, `complete`, `reject`, `claimRefund`, `getJob`
- `arc.identity.*` — ERC-8004 IdentityRegistry: `register`, `ownerOf`, `tokenURI`, `balanceOf`
- `arc.reputation.*` — ERC-8004 ReputationRegistry: `giveFeedback`, `getFeedback`
- `arc.validation.*` — ERC-8004 ValidationRegistry: `validationRequest`, `validationResponse`, `getValidationStatus`
- `arc.usdc.*` — USDC: `balanceOf`, `allowance`, `approve`

## License

MIT
