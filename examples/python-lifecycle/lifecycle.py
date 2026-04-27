"""Full ERC-8183 lifecycle on Arc testnet — single-wallet self-roleplay.

Run: `python lifecycle.py` after setting PRIVATE_KEY in .env.
"""

import os
import sys

from dotenv import load_dotenv

from arckit import ArcKit, JobStatus

load_dotenv()

private_key = os.environ.get("PRIVATE_KEY")
if not private_key or private_key == "0x":
    sys.exit("Set PRIVATE_KEY in .env (and fund it via the Arc faucet)")

arc = ArcKit(
    private_key=private_key,
    network="testnet",
    rpc_url=os.environ.get("RPC_URL"),
)
me = arc.address
print(f"Wallet: {me}")

balance = arc.usdc.balance_of(me)
print(f"USDC balance: {balance}")

if balance < 0.01:
    sys.exit("Address has < 0.01 USDC. Fund it from the Arc faucet first.")

# Single wallet plays client + provider + evaluator for a self-contained demo.
print("\n[1/4] Creating job...")
job_id = arc.commerce.create_job(
    provider=me,
    evaluator=me,
    description="demo: self-roleplayed code review",
    expired_at_hours=1,
)
print(f"  Job created: id={job_id}")

print("\n[2/4] Setting budget (0.01 USDC)...")
arc.commerce.set_budget(job_id, 0.01)
print("  Budget set.")

print("\n[3/4] Funding job...")
arc.commerce.fund(job_id)  # auto-approves USDC
print("  Job funded.")

print("\n[4/4] Submitting deliverable + completing...")
arc.commerce.submit(job_id, "demo deliverable hash")
arc.commerce.complete(job_id, "looks good")

final = arc.commerce.get_job(job_id)
print(f"\nFinal status: {JobStatus(final.status).name} ({final.status})")
print("Explorer: https://testnet.arcscan.app")
