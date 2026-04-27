# {{projectName}}

A minimal Arc agent commerce app, scaffolded by [`create-arc-app`](https://github.com/Ridwannurudeen/arckit).

Demonstrates the full ERC-8183 lifecycle on Arc testnet: register an agent, create a job, fund it with USDC, submit a deliverable, and complete the job.

## Setup

```bash
npm install
cp .env.example .env
# add your private key (use a fresh testnet key — fund it at the Arc faucet)
```

## Run

Run the full lifecycle in one shot:

```bash
npm run lifecycle
```

Or register an agent identity (ERC-8004):

```bash
npm run register-agent
```

## What's inside

- `src/lifecycle.ts` — script that walks through createJob → setBudget → fund → submit → complete using a single wallet for all three roles (client/provider/evaluator) so you can run end-to-end on testnet without coordinating multiple keys
- `src/register-agent.ts` — register an agent on the ERC-8004 IdentityRegistry

## Next steps

- Read the [@arckit/sdk docs](https://github.com/Ridwannurudeen/arckit/tree/main/packages/sdk)
- Browse the [hook templates](https://github.com/Ridwannurudeen/arckit/tree/main/packages/hooks) (MultiEvaluator, Milestone, Escalation, etc.)
- Use the [Python SDK](https://pypi.org/project/arckit/) if your agent is in Python
