# @arckit/hooks

Production-grade `IACPHook` Solidity templates for Arc's ERC-8183 AgenticCommerce.

The `hook` parameter on every ERC-8183 job is the standard's extensibility primitive — but Arc's tutorials hardcode it to `address(0)` because no template library exists. This package fixes that.

## Templates

| Hook | Use case |
|---|---|
| `MultiEvaluatorHook` | N-of-M quorum acceptance — N evaluators must accept before a job completes |
| `MilestoneHook` | Staged budget release on milestone events instead of single-payment |
| `TimeDecayReputationHook` | Provider reputation decays without renewal — incentivizes ongoing quality |
| `EscalationHook` | Single-arbiter dispute escalation when client and provider disagree |
| `MultiStablecoinHook` | Accept BRLA / PHPC / JPYC / QCAD via on-the-fly StableFX swap to USDC |

## Usage

Pass the deployed hook address as the `hook` parameter when creating an ERC-8183 job:

```solidity
import { IAgenticCommerce } from "@arckit/hooks/interfaces/IAgenticCommerce.sol";

IAgenticCommerce arc = IAgenticCommerce(0x0747EEf0706327138c69792bF28Cd525089e4583);

uint256 jobId = arc.createJob({
    provider: providerAddr,
    evaluator: evaluatorAddr,
    expiredAt: block.timestamp + 1 days,
    description: "Audit my contract",
    hook: deployedMultiEvaluatorHook  // <-- the hook
});
```

## Deployed addresses (Arc testnet)

To be populated after first deploy.

## Build & test

```bash
forge install
forge build
forge test
```

## License

MIT
