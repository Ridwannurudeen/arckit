"""ERC-8183 AgenticCommerce client."""

from __future__ import annotations

import time

from web3 import Web3

from arckit._tx import TxContext, deliverable_to_bytes32
from arckit.abi import AGENTIC_COMMERCE_ABI, ERC20_ABI
from arckit.errors import JobNotFoundError
from arckit.types import Job, JobStatus
from arckit.utils import to_usdc_base

ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


class CommerceClient:
    """Wraps the canonical ERC-8183 AgenticCommerce contract on Arc."""

    def __init__(self, ctx: TxContext, agentic_commerce_address: str, usdc_address: str):
        self._ctx = ctx
        self._contract = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(agentic_commerce_address),
            abi=AGENTIC_COMMERCE_ABI,
        )
        self._usdc = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(usdc_address), abi=ERC20_ABI
        )

    # ── Reads ──

    def get_job(self, job_id: int) -> Job:
        raw = self._contract.functions.getJob(int(job_id)).call()
        if raw[0] == 0 and job_id != 0:
            raise JobNotFoundError(job_id)
        return Job(
            id=raw[0],
            client=raw[1],
            provider=raw[2],
            evaluator=raw[3],
            description=raw[4],
            budget=raw[5],
            expired_at=raw[6],
            status=JobStatus(raw[7]),
            hook=raw[8],
        )

    def job_counter(self) -> int:
        return self._contract.functions.jobCounter().call()

    def payment_token(self) -> str:
        return self._contract.functions.paymentToken().call()

    # ── Writes ──

    def create_job(
        self,
        provider: str,
        evaluator: str,
        description: str,
        expired_at_hours: float | None = None,
        expired_at: int | None = None,
        hook: str = ZERO_ADDRESS,
    ) -> int:
        """Create a new job. Returns the new job ID.

        Pass either ``expired_at`` (absolute unix timestamp) or
        ``expired_at_hours`` (relative hours from now).
        """
        if expired_at is None:
            if expired_at_hours is None:
                raise ValueError("Pass either expired_at or expired_at_hours")
            expired_at = int(time.time() + expired_at_hours * 3600)
        receipt = self._ctx.send(
            self._contract.functions.createJob(
                Web3.to_checksum_address(provider),
                Web3.to_checksum_address(evaluator),
                int(expired_at),
                description,
                Web3.to_checksum_address(hook),
            )
        )
        args = self._ctx.event_args(receipt, self._contract, "JobCreated")
        if args is None:
            raise RuntimeError("JobCreated event missing from receipt")
        return int(args["jobId"])

    def set_budget(self, job_id: int, amount_usdc: float | int, opt_params: bytes = b"") -> dict:
        return self._ctx.send(
            self._contract.functions.setBudget(int(job_id), to_usdc_base(amount_usdc), opt_params)
        )

    def fund(self, job_id: int, opt_params: bytes = b"", auto_approve: bool = True) -> dict:
        """Fund a job. Auto-approves USDC by default."""
        acc = self._ctx.require_account("fund")
        job = self.get_job(int(job_id))
        if auto_approve:
            allowance = self._usdc.functions.allowance(
                acc.address, self._contract.address
            ).call()
            if allowance < job.budget:
                self._ctx.send(
                    self._usdc.functions.approve(self._contract.address, job.budget)
                )
        return self._ctx.send(self._contract.functions.fund(int(job_id), opt_params))

    def submit(self, job_id: int, deliverable: str | bytes, opt_params: bytes = b"") -> dict:
        return self._ctx.send(
            self._contract.functions.submit(
                int(job_id), deliverable_to_bytes32(deliverable), opt_params
            )
        )

    def complete(
        self, job_id: int, reason: str | bytes = "accepted", opt_params: bytes = b""
    ) -> dict:
        return self._ctx.send(
            self._contract.functions.complete(
                int(job_id), deliverable_to_bytes32(reason), opt_params
            )
        )

    def reject(
        self, job_id: int, reason: str | bytes = "rejected", opt_params: bytes = b""
    ) -> dict:
        return self._ctx.send(
            self._contract.functions.reject(
                int(job_id), deliverable_to_bytes32(reason), opt_params
            )
        )

    def claim_refund(self, job_id: int) -> dict:
        return self._ctx.send(self._contract.functions.claimRefund(int(job_id)))
