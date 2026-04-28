import type { Account, Address, Hex, PublicClient, WalletClient } from 'viem';
import { validationRegistryAbi } from '../abi/validationRegistry.js';
import { WalletRequiredError } from '../errors.js';
import type { ValidationResponse, ValidationStatus } from '../types.js';
import { hashString, waitForReceipt } from '../utils.js';

export type ValidationClientOpts = {
  publicClient: PublicClient;
  walletClient?: WalletClient;
  account?: Account;
  validationRegistry: Address;
};

export class ValidationClient {
  constructor(private readonly opts: ValidationClientOpts) {}

  // ── Reads ──

  async getValidationStatus(requestHash: Hex): Promise<ValidationStatus> {
    const raw = await this.opts.publicClient.readContract({
      address: this.opts.validationRegistry,
      abi: validationRegistryAbi,
      functionName: 'getValidationStatus',
      args: [requestHash],
    });
    return {
      validatorAddress: raw[0],
      agentId: raw[1],
      response: raw[2] as ValidationResponse,
      responseHash: raw[3],
      tag: raw[4],
      lastUpdate: raw[5],
    };
  }

  // ── Writes ──

  async validationRequest(params: {
    validator: Address;
    agentId: bigint | number;
    requestURI: string;
    requestHash?: Hex;
  }) {
    const { account, walletClient } = this.requireWallet('validationRequest');
    const requestHash = params.requestHash ?? hashString(params.requestURI);
    const hash = await walletClient.writeContract({
      account,
      chain: null,
      address: this.opts.validationRegistry,
      abi: validationRegistryAbi,
      functionName: 'validationRequest',
      args: [params.validator, BigInt(params.agentId), params.requestURI, requestHash],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  async validationResponse(params: {
    requestHash: Hex;
    response: ValidationResponse;
    responseURI: string;
    tag?: string;
    responseHash?: Hex;
  }) {
    const { account, walletClient } = this.requireWallet('validationResponse');
    const responseHash = params.responseHash ?? hashString(params.responseURI);
    const tag = params.tag ?? '';
    const hash = await walletClient.writeContract({
      account,
      chain: null,
      address: this.opts.validationRegistry,
      abi: validationRegistryAbi,
      functionName: 'validationResponse',
      args: [params.requestHash, params.response, params.responseURI, responseHash, tag],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  private requireWallet(op: string): { account: Account; walletClient: WalletClient } {
    if (!this.opts.account || !this.opts.walletClient) {
      throw new WalletRequiredError(op);
    }
    return { account: this.opts.account, walletClient: this.opts.walletClient };
  }
}
