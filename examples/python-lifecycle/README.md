# python-lifecycle

End-to-end ERC-8183 lifecycle on Arc testnet using the [arckit](https://pypi.org/project/arckit/) Python SDK.

A single wallet plays all three roles (client / provider / evaluator) so you can run it end-to-end without coordinating multiple keys.

## Run

```bash
pip install -e .
cp .env.example .env
# add your testnet PRIVATE_KEY (fund the address at the Arc faucet)
python lifecycle.py
```

## What it does

1. Loads your wallet
2. Creates a job with a 1-hour expiry
3. Provider sets a 0.01 USDC budget
4. Client funds the job (auto-approves USDC)
5. Provider submits a deliverable hash
6. Evaluator completes the job and releases payment
7. Prints final job status

For a multi-wallet flow, split the lifecycle across three terminals each holding a different `PRIVATE_KEY`.
