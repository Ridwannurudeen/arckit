import type { Account, Address, Hex, PublicClient, WalletClient } from 'viem';
import { validationRegistryAbi } from '../abi/validationRegistry.js';
import { WalletRequiredError } from '../errors.js';
import { type ValidationStatus, ValidationResponse } from '../types.js';
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
    const account = this.requireAccount('validationRequest');
    const requestHash = params.requestHash ?? hashString(params.requestURI);
    const hash = await this.opts.walletClient!.writeContract({
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
    const account = this.requireAccount('validationResponse');
    const responseHash = params.responseHash ?? hashString(params.responseURI);
    const tag = params.tag ?? '';
    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.validationRegistry,
      abi: validationRegistryAbi,
      functionName: 'validationResponse',
      args: [params.requestHash, params.response, params.responseURI, responseHash, tag],
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
