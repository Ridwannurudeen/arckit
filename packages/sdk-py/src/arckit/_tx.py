"""Internal transaction send/wait helpers used by sync sub-clients."""

from __future__ import annotations

import time
from typing import Any

from eth_account.signers.local import LocalAccount
from web3 import Web3

from arckit.errors import (
    InsufficientBalanceError,
    TransactionRevertedError,
    TransactionTimeoutError,
    WalletRequiredError,
)


class TxContext:
    """Shared transaction state for all sync sub-clients."""

    def __init__(
        self,
        w3: Web3,
        account: LocalAccount | None,
        chain_id: int,
        tx_timeout: int = 120,
    ):
        self.w3 = w3
        self.account = account
        self.chain_id = chain_id
        self.tx_timeout = tx_timeout
        self._nonce: int | None = None

    def require_account(self, op: str) -> LocalAccount:
        if self.account is None:
            raise WalletRequiredError(op)
        return self.account

    def _next_nonce(self) -> int:
        acc = self.require_account("_next_nonce")
        if self._nonce is None:
            self._nonce = self.w3.eth.get_transaction_count(acc.address, "pending")
        else:
            self._nonce += 1
        return self._nonce

    def reset_nonce(self) -> None:
        self._nonce = None

    def send(self, fn: Any) -> dict:
        acc = self.require_account("send")
        try:
            tx = fn.build_transaction(
                {"from": acc.address, "nonce": self._next_nonce(), "chainId": self.chain_id}
            )
            estimated = self.w3.eth.estimate_gas(tx)
            tx["gas"] = int(estimated * 1.2)
            signed = acc.sign_transaction(tx)
            tx_hash = self.w3.eth.send_raw_transaction(signed.raw_transaction)
            try:
                receipt = self.w3.eth.wait_for_transaction_receipt(
                    tx_hash, timeout=self.tx_timeout
                )
            except Exception as exc:
                if "timeout" in str(exc).lower() or "TimeExhausted" in type(exc).__name__:
                    raise TransactionTimeoutError(tx_hash.hex(), self.tx_timeout) from exc
                raise

            if receipt["status"] != 1:
                reason = ""
                try:
                    self.w3.eth.call(tx, block_identifier=receipt["blockNumber"])
                except Exception as call_err:
                    reason = str(call_err)
                if "insufficient" in reason.lower():
                    raise InsufficientBalanceError(reason)
                raise TransactionRevertedError(tx_hash.hex(), reason)
            return receipt
        except Exception:
            self.reset_nonce()
            raise

    def event_args(self, receipt: dict, contract: Any, event_name: str) -> dict | None:
        """Return the args of the first matching event in the receipt, or None."""
        event = getattr(contract.events, event_name)()
        try:
            logs = event.process_receipt(receipt)
        except Exception:
            return None
        if not logs:
            return None
        return dict(logs[0]["args"])


def truthy_default(value: str | None, default: str = "") -> str:
    return value if value is not None else default


def deliverable_to_bytes32(deliverable: str | bytes) -> bytes:
    """Accept a 0x-prefixed bytes32 hex or a UTF-8 string and return 32 bytes."""
    if isinstance(deliverable, (bytes, bytearray)):
        if len(deliverable) != 32:
            raise ValueError(f"deliverable bytes must be exactly 32 bytes, got {len(deliverable)}")
        return bytes(deliverable)
    if deliverable.startswith("0x") and len(deliverable) == 66:
        return bytes.fromhex(deliverable[2:])
    return Web3.keccak(text=deliverable)


def maybe_sleep(_: float) -> None:
    """Sleep stub kept for symmetry with the async client."""
    time.sleep(0)
