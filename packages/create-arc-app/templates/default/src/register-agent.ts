import { ArcKit } from '@arckit/sdk';
import { privateKeyToAccount } from 'viem/accounts';

const PRIVATE_KEY = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY || PRIVATE_KEY === '0x') {
  throw new Error('Set PRIVATE_KEY in .env');
}

const METADATA_URI = process.env.METADATA_URI ?? 'ipfs://example-agent-metadata';

const account = privateKeyToAccount(PRIVATE_KEY as `0x${string}`);
const arc = new ArcKit({ account, network: 'testnet' });

console.log(`Registering agent for ${account.address}`);
console.log(`Metadata URI: ${METADATA_URI}`);

const agentId = await arc.identity.register({ metadataURI: METADATA_URI });
console.log(`\nRegistered. Agent ID: ${agentId}`);

const agent = await arc.identity.getAgent(agentId);
console.log(`Owner: ${agent.owner}`);
console.log(`Metadata: ${agent.metadataURI}`);
