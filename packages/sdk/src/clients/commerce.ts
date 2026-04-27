import {
  type Account,
  type Address,
  type Hex,
  type PublicClient,
  type WalletClient,
  zeroAddress,
} from 'viem';
import { agenticCommerceAbi } from '../abi/agenticCommerce.js';
import { erc20Abi } from '../abi/erc20.js';
import { JobNotFoundError, WalletRequiredError } from '../errors.js';
import { type CreateJobParams, type Job, JobStatus } from '../types.js';
import { findEvent, hashString, toUsdcBase, waitForReceipt } from '../utils.js';

export type CommerceClientOpts = {
  publicClient: PublicClient;
  walletClient?: WalletClient;
  account?: Account;
  agenticCommerce: Address;
  usdc: Address;
};

export class CommerceClient {
  constructor(private readonly opts: CommerceClientOpts) {}

  // ── Reads ──

  async getJob(jobId: bigint | number): Promise<Job> {
    const id = BigInt(jobId);
    const raw = await this.opts.publicClient.readContract({
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'getJob',
      args: [id],
    });
    if (raw.id === 0n && id !== 0n) throw new JobNotFoundError(id);
    return {
      id: raw.id,
      client: raw.client,
      provider: raw.provider,
      evaluator: raw.evaluator,
      description: raw.description,
      budget: raw.budget,
      expiredAt: raw.expiredAt,
      status: raw.status as JobStatus,
      hook: raw.hook,
    };
  }

  async jobCounter(): Promise<bigint> {
    return this.opts.publicClient.readContract({
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'jobCounter',
    });
  }

  async paymentToken(): Promise<Address> {
    return this.opts.publicClient.readContract({
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'paymentToken',
    });
  }

  // ── Writes ──

  async createJob(params: CreateJobParams): Promise<bigint> {
    const account = this.requireAccount('createJob');
    const expiredAt = BigInt(params.expiredAt);
    const hook = params.hook ?? zeroAddress;

    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'createJob',
      args: [params.provider, params.evaluator, expiredAt, params.description, hook],
    });
    const receipt = await waitForReceipt(this.opts.publicClient, hash);
    const event = findEvent<{ jobId: bigint }>(receipt.logs, agenticCommerceAbi, 'JobCreated');
    if (!event) throw new Error('JobCreated event not found in receipt');
    return event.jobId;
  }

  async setBudget(jobId: bigint | number, amountUsdc: number | bigint, optParams: Hex = '0x') {
    const account = this.requireAccount('setBudget');
    const amount = toUsdcBase(amountUsdc);
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'setBudget',
      args: [BigInt(jobId), amount, optParams],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  /// Fund a job. Auto-approves USDC if allowance is insufficient (set autoApprove=false to skip).
  async fund(
    jobId: bigint | number,
    opts: { optParams?: Hex; autoApprove?: boolean } = {},
  ) {
    const account = this.requireAccount('fund');
    const id = BigInt(jobId);
    const job = await this.getJob(id);

    if (opts.autoApprove !== false) {
      const allowance = await this.opts.publicClient.readContract({
        address: this.opts.usdc,
        abi: erc20Abi,
        functionName: 'allowance',
        args: [account.address, this.opts.agenticCommerce],
      });
      if (allowance < job.budget) {
        const approveHash = await this.opts.walletClient!.writeContract({
          account,
          chain: null,
          address: this.opts.usdc,
          abi: erc20Abi,
          functionName: 'approve',
          args: [this.opts.agenticCommerce, job.budget],
        });
        await waitForReceipt(this.opts.publicClient, approveHash);
      }
    }

    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'fund',
      args: [id, opts.optParams ?? '0x'],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async submit(jobId: bigint | number, deliverable: Hex | string, optParams: Hex = '0x') {
    const account = this.requireAccount('submit');
    const deliverableHash = deliverable.startsWith('0x') && deliverable.length === 66
      ? (deliverable as Hex)
      : hashString(deliverable);
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'submit',
      args: [BigInt(jobId), deliverableHash, optParams],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async complete(
    jobId: bigint | number,
    reason: Hex | string = 'accepted',
    optParams: Hex = '0x',
  ) {
    const account = this.requireAccount('complete');
    const reasonHash = reason.startsWith('0x') && reason.length === 66
      ? (reason as Hex)
      : hashString(reason);
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'complete',
      args: [BigInt(jobId), reasonHash, optParams],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async reject(
    jobId: bigint | number,
    reason: Hex | string = 'rejected',
    optParams: Hex = '0x',
  ) {
    const account = this.requireAccount('reject');
    const reasonHash = reason.startsWith('0x') && reason.length === 66
      ? (reason as Hex)
      : hashString(reason);
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'reject',
      args: [BigInt(jobId), reasonHash, optParams],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async claimRefund(jobId: bigint | number) {
    const account = this.requireAccount('claimRefund');
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.agenticCommerce,
      abi: agenticCommerceAbi,
      functionName: 'claimRefund',
      args: [BigInt(jobId)],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  private requireAccount(op: string): Account {
    if (!this.opts.account || !this.opts.walletClient) {
      throw new WalletRequiredError(op);
    }
    return this.opts.account;
  }
}
