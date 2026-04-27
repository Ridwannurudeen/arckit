import type { Address, Hex } from 'viem';

export enum JobStatus {
  Open = 0,
  Funded = 1,
  Submitted = 2,
  Completed = 3,
  Rejected = 4,
  Expired = 5,
}

export type Job = {
  id: bigint;
  client: Address;
  provider: Address;
  evaluator: Address;
  description: string;
  budget: bigint;
  expiredAt: bigint;
  status: JobStatus;
  hook: Address;
};

export enum FeedbackCategory {
  Quality = 0,
  Reliability = 1,
  Speed = 2,
  Communication = 3,
  Other = 4,
}

export type Feedback = {
  agentId: bigint;
  from: Address;
  score: number;
  feedbackType: FeedbackCategory;
  feedbackHash: Hex;
};

export type Agent = {
  agentId: bigint;
  owner: Address;
  metadataURI: string;
};

export enum ValidationResponse {
  Pending = 0,
  Approved = 1,
  Rejected = 2,
}

export type ValidationStatus = {
  validatorAddress: Address;
  agentId: bigint;
  response: ValidationResponse;
  responseHash: Hex;
  tag: string;
  lastUpdate: bigint;
};

export type CreateJobParams = {
  provider: Address;
  evaluator: Address;
  expiredAt: bigint | number;
  description: string;
  hook?: Address;
};

export type GiveFeedbackParams = {
  agentId: bigint | number;
  score: number;
  feedbackType: FeedbackCategory;
  tag?: string;
  metadataURI?: string;
  evidenceURI?: string;
  comment?: string;
  feedbackHash?: Hex;
};
