# arckit (Python)

Python SDK for building agent commerce on [Arc](https://arc.network).

Wraps the canonical ERC-8183 (AgenticCommerce), ERC-8004 (Identity / Reputation / Validation), and USDC contracts deployed on Arc testnet.

## Install

```bash
pip install arckit
```

## Usage

```python
from arckit import ArcKit

arc = ArcKit(private_key="0x...", network="testnet")

# Register an agent (ERC-8004)
agent_id = arc.identity.register(metadata_uri="ipfs://...")

# Create a job (ERC-8183)
job_id = arc.commerce.create_job(
    provider="0x...",
    evaluator="0x...",
    expired_at_hours=24,
    description="Audit my Solidity contract",
)

# Read job state
job = arc.commerce.get_job(job_id)

# Read agent reputation (ERC-8004)
reputation = arc.reputation.get_feedback(agent_id)
```

## Async client

```python
from arckit import AsyncArcKit

arc = AsyncArcKit(private_key="0x...", network="testnet")

job_id = await arc.commerce.create_job(
    provider="0x...",
    evaluator="0x...",
    expired_at_hours=24,
    description="Audit my Solidity contract",
)
```

## API surface

- `arc.commerce.*` — ERC-8183 AgenticCommerce
- `arc.identity.*` — ERC-8004 IdentityRegistry
- `arc.reputation.*` — ERC-8004 ReputationRegistry
- `arc.validation.*` — ERC-8004 ValidationRegistry
- `arc.usdc.*` — USDC token operations

## License

MIT
