import type { Account, Address, PublicClient, WalletClient } from 'viem';
import { erc20Abi } from '../abi/erc20.js';
import { WalletRequiredError } from '../errors.js';
import { fromUsdcBase, toUsdcBase, waitForReceipt } from '../utils.js';

export type UsdcClientOpts = {
  publicClient: PublicClient;
  walletClient?: WalletClient;
  account?: Account;
  usdc: Address;
};

export class UsdcClient {
  constructor(private readonly opts: UsdcClientOpts) {}

  /// Get raw balance (base units, 6 decimals).
  async balanceOfRaw(account: Address): Promise<bigint> {
    return this.opts.publicClient.readContract({
      address: this.opts.usdc,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [account],
    });
  }

  /// Get balance as a USDC float (e.g. 12.5 for 12.5 USDC).
  async balanceOf(account: Address): Promise<number> {
    return fromUsdcBase(await this.balanceOfRaw(account));
  }

  async allowance(owner: Address, spender: Address): Promise<bigint> {
    return this.opts.publicClient.readContract({
      address: this.opts.usdc,
      abi: erc20Abi,
      functionName: 'allowance',
      args: [owner, spender],
    });
  }

  async approve(spender: Address, amount: number | bigint) {
    const account = this.requireAccount('approve');
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.usdc,
      abi: erc20Abi,
      functionName: 'approve',
      args: [spender, toUsdcBase(amount)],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async transfer(to: Address, amount: number | bigint) {
    const account = this.requireAccount('transfer');
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.usdc,
      abi: erc20Abi,
      functionName: 'transfer',
      args: [to, toUsdcBase(amount)],
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
