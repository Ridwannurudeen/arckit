import type { Account, Address, PublicClient, WalletClient } from 'viem';
import { identityRegistryAbi } from '../abi/identityRegistry.js';
import { AgentNotFoundError, WalletRequiredError } from '../errors.js';
import type { Agent } from '../types.js';
import { findEvent, waitForReceipt } from '../utils.js';

export type IdentityClientOpts = {
  publicClient: PublicClient;
  walletClient?: WalletClient;
  account?: Account;
  identityRegistry: Address;
};

export class IdentityClient {
  constructor(private readonly opts: IdentityClientOpts) {}

  // ── Reads ──

  async ownerOf(agentId: bigint | number): Promise<Address> {
    const id = BigInt(agentId);
    try {
      return await this.opts.publicClient.readContract({
        address: this.opts.identityRegistry,
        abi: identityRegistryAbi,
        functionName: 'ownerOf',
        args: [id],
      });
    } catch {
      throw new AgentNotFoundError(id);
    }
  }

  async tokenURI(agentId: bigint | number): Promise<string> {
    return this.opts.publicClient.readContract({
      address: this.opts.identityRegistry,
      abi: identityRegistryAbi,
      functionName: 'tokenURI',
      args: [BigInt(agentId)],
    });
  }

  async balanceOf(owner: Address): Promise<bigint> {
    return this.opts.publicClient.readContract({
      address: this.opts.identityRegistry,
      abi: identityRegistryAbi,
      functionName: 'balanceOf',
      args: [owner],
    });
  }

  async getAgent(agentId: bigint | number): Promise<Agent> {
    const id = BigInt(agentId);
    const [owner, metadataURI] = await Promise.all([this.ownerOf(id), this.tokenURI(id)]);
    return { agentId: id, owner, metadataURI };
  }

  // ── Writes ──

  async register(params: { metadataURI: string }): Promise<bigint> {
    const account = this.requireAccount('register');
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.identityRegistry,
      abi: identityRegistryAbi,
      functionName: 'register',
      args: [params.metadataURI],
    });
    const receipt = await waitForReceipt(this.opts.publicClient, hash);
    const event = findEvent<{ tokenId: bigint }>(receipt.logs, identityRegistryAbi, 'Transfer');
    if (!event) throw new Error('Transfer event not found in receipt');
    return event.tokenId;
  }

  private requireAccount(op: string): Account {
    if (!this.opts.account || !this.opts.walletClient) {
      throw new WalletRequiredError(op);
    }
    return this.opts.account;
  }
}
