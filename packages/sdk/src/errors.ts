export class ArcKitError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ArcKitError';
  }
}

export class TransactionRevertedError extends ArcKitError {
  txHash: string;
  reason?: string;
  constructor(txHash: string, reason?: string) {
    super(`Transaction reverted${reason ? `: ${reason}` : ''} (tx: ${txHash})`);
    this.name = 'TransactionRevertedError';
    this.txHash = txHash;
    this.reason = reason;
  }
}

export class TransactionTimeoutError extends ArcKitError {
  txHash: string;
  timeoutMs: number;
  constructor(txHash: string, timeoutMs: number) {
    super(`Transaction ${txHash} timed out after ${timeoutMs}ms`);
    this.name = 'TransactionTimeoutError';
    this.txHash = txHash;
    this.timeoutMs = timeoutMs;
  }
}

export class InsufficientBalanceError extends ArcKitError {
  constructor(message: string) {
    super(message);
    this.name = 'InsufficientBalanceError';
  }
}

export class JobNotFoundError extends ArcKitError {
  jobId: bigint;
  constructor(jobId: bigint) {
    super(`Job ${jobId} not found`);
    this.name = 'JobNotFoundError';
    this.jobId = jobId;
  }
}

export class AgentNotFoundError extends ArcKitError {
  agentId: bigint;
  constructor(agentId: bigint) {
    super(`Agent ${agentId} not found`);
    this.name = 'AgentNotFoundError';
    this.agentId = agentId;
  }
}

export class WalletRequiredError extends ArcKitError {
  constructor(operation: string) {
    super(`Wallet required for ${operation}. Pass an account when constructing ArcKit.`);
    this.name = 'WalletRequiredError';
  }
}
