"""Typed exceptions for ArcKit operations."""


class ArcKitError(Exception):
    """Base exception for all ArcKit failures."""


class TransactionRevertedError(ArcKitError):
    def __init__(self, tx_hash: str, reason: str = ""):
        super().__init__(f"Transaction reverted{f': {reason}' if reason else ''} (tx: {tx_hash})")
        self.tx_hash = tx_hash
        self.reason = reason


class TransactionTimeoutError(ArcKitError):
    def __init__(self, tx_hash: str, timeout_seconds: int):
        super().__init__(f"Transaction {tx_hash} timed out after {timeout_seconds}s")
        self.tx_hash = tx_hash
        self.timeout_seconds = timeout_seconds


class InsufficientBalanceError(ArcKitError):
    pass


class JobNotFoundError(ArcKitError):
    def __init__(self, job_id: int):
        super().__init__(f"Job {job_id} not found")
        self.job_id = job_id


class AgentNotFoundError(ArcKitError):
    def __init__(self, agent_id: int):
        super().__init__(f"Agent {agent_id} not found")
        self.agent_id = agent_id


class WalletRequiredError(ArcKitError):
    def __init__(self, operation: str):
        super().__init__(
            f"Wallet required for {operation}. Pass private_key when constructing ArcKit."
        )
