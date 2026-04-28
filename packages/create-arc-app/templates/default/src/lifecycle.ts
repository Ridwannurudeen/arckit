import { ArcKit, JobStatus } from '@arckit/sdk';
import { privateKeyToAccount } from 'viem/accounts';

const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY || PRIVATE_KEY === '0x') {
  throw new Error('Set PRIVATE_KEY in .env (and fund the address via the Arc faucet)');
}

const account = privateKeyToAccount(PRIVATE_KEY as `0x${string}`);
const arc = new ArcKit({ account, network: 'testnet', rpcUrl: process.env.RPC_URL });

console.log(`Wallet: ${account.address}`);

const usdcBalance = await arc.usdc.balanceOf(account.address);
console.log(`USDC balance: ${usdcBalance}`);

if (usdcBalance < 0.01) {
  throw new Error(
    'Address has < 0.01 USDC. Fund it from the Arc faucet at https://testnet.arcscan.app first.',
  );
}

// For a self-contained demo we use the same wallet as client, provider, and evaluator.
// In a real app these would be three different addresses.
console.log('\n[1/4] Creating job...');
const jobId = await arc.commerce.createJob({
  provider: account.address,
  evaluator: account.address,
  expiredAt: Math.floor(Date.now() / 1000) + 3600,
  description: 'demo: self-roleplayed code review',
});
console.log(`  Job created: id=${jobId}`);

console.log('\n[2/4] Setting budget (0.01 USDC)...');
await arc.commerce.setBudget(jobId, 0.01);
console.log('  Budget set.');

console.log('\n[3/4] Funding job...');
await arc.commerce.fund(jobId); // auto-approves USDC
console.log('  Job funded.');

console.log('\n[4/4] Submitting deliverable + completing...');
await arc.commerce.submit(jobId, 'demo deliverable hash');
await arc.commerce.complete(jobId, 'looks good');

const final = await arc.commerce.getJob(jobId);
console.log(`\nFinal status: ${JobStatus[final.status]} (${final.status})`);
console.log('Explorer: https://testnet.arcscan.app/tx');
