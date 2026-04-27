import { type Account, type Address, type Hex, type PublicClient, type WalletClient, zeroHash } from 'viem';
import { reputationRegistryAbi } from '../abi/reputationRegistry.js';
import { WalletRequiredError } from '../errors.js';
import { FeedbackCategory, type GiveFeedbackParams } from '../types.js';
import { hashString, waitForReceipt } from '../utils.js';

export type ReputationClientOpts = {
  publicClient: PublicClient;
  walletClient?: WalletClient;
  account?: Account;
  reputationRegistry: Address;
};

export class ReputationClient {
  constructor(private readonly opts: ReputationClientOpts) {}

  /// Submit feedback for an agent. Per ERC-8004, an agent owner cannot submit
  /// feedback for their own agent (the contract reverts).
  async giveFeedback(params: GiveFeedbackParams) {
    const account = this.requireAccount('giveFeedback');
    const tag = params.tag ?? '';
    const metadataURI = params.metadataURI ?? '';
    const evidenceURI = params.evidenceURI ?? '';
    const comment = params.comment ?? '';
    const feedbackHash =
      params.feedbackHash ?? (comment ? hashString(comment) : (zeroHash as Hex));

    const hash = await this.opts.walletClient!.writeContract({
      account,
      chain: null,
      address: this.opts.reputationRegistry,
      abi: reputationRegistryAbi,
      functionName: 'giveFeedback',
      args: [
        BigInt(params.agentId),
        BigInt(params.score),
        params.feedbackType,
        tag,
        metadataURI,
        evidenceURI,
        comment,
        feedbackHash,
      ],
    });
    return waitForReceipt(this.opts.publicClient, hash);
  }

  /// Convenience: submit a positive (or negative) score with no metadata.
  /// Score is bounded by int128 range.
  async quickFeedback(
    agentId: bigint | number,
    score: number,
    category: FeedbackCategory = FeedbackCategory.Quality,
  ) {
    return this.giveFeedback({ agentId, score, feedbackType: category });
  }

  private requireAccount(op: string): Account {
    if (!this.opts.account || !this.opts.walletClient) {
      throw new WalletRequiredError(op);
    }
    return this.opts.account;
  }
}
