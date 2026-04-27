"""ERC-8004 ReputationRegistry client."""

from __future__ import annotations

from web3 import Web3

from arckit._tx import TxContext
from arckit.abi import REPUTATION_REGISTRY_ABI
from arckit.types import FeedbackCategory
from arckit.utils import hash_string

ZERO_HASH = b"\x00" * 32


class ReputationClient:
    def __init__(self, ctx: TxContext, reputation_registry_address: str):
        self._ctx = ctx
        self._contract = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(reputation_registry_address),
            abi=REPUTATION_REGISTRY_ABI,
        )

    def give_feedback(
        self,
        agent_id: int,
        score: int,
        feedback_type: FeedbackCategory = FeedbackCategory.QUALITY,
        tag: str = "",
        metadata_uri: str = "",
        evidence_uri: str = "",
        comment: str = "",
        feedback_hash: bytes | None = None,
    ) -> dict:
        """Submit feedback for an agent (per ERC-8004, owner cannot self-rate)."""
        if feedback_hash is None:
            feedback_hash = hash_string(comment) if comment else ZERO_HASH
        return self._ctx.send(
            self._contract.functions.giveFeedback(
                int(agent_id),
                int(score),
                int(feedback_type),
                tag,
                metadata_uri,
                evidence_uri,
                comment,
                feedback_hash,
            )
        )

    def quick_feedback(
        self,
        agent_id: int,
        score: int,
        category: FeedbackCategory = FeedbackCategory.QUALITY,
    ) -> dict:
        return self.give_feedback(agent_id=agent_id, score=score, feedback_type=category)
