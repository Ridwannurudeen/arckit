"""LangChain Tool bindings for ArcKit.

Each LangChain Tool wraps a single ArcKit operation. Tool inputs are validated
via Pydantic models so the LLM always receives strongly typed schemas.
"""

from __future__ import annotations

from typing import Any

from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field

from arckit import ArcKit, JobStatus

# ── Input schemas ──


class CreateJobInput(BaseModel):
    provider: str = Field(description="Provider wallet address (0x...)")
    evaluator: str = Field(description="Evaluator wallet address (0x...)")
    description: str = Field(description="Human-readable job description")
    expired_at_hours: float = Field(
        default=24, description="Hours from now until the job expires"
    )


class JobIdInput(BaseModel):
    job_id: int = Field(description="The ERC-8183 job ID")


class SetBudgetInput(BaseModel):
    job_id: int
    amount_usdc: float = Field(description="Budget in USDC (e.g. 0.5 = 0.5 USDC)")


class SubmitInput(BaseModel):
    job_id: int
    deliverable: str = Field(description="Deliverable description or 32-byte hex hash")


class CompleteInput(BaseModel):
    job_id: int
    reason: str = Field(default="accepted", description="Reason for completion")


class RegisterAgentInput(BaseModel):
    metadata_uri: str = Field(description="IPFS or HTTPS URI pointing to agent metadata JSON")


# ── Tool factory ──


def build_arc_tools(
    private_key: str,
    network: str = "testnet",
    rpc_url: str | None = None,
) -> list[StructuredTool]:
    """Build the full set of LangChain tools backed by a single ArcKit client."""
    arc = ArcKit(private_key=private_key, network=network, rpc_url=rpc_url)

    def _create_job(
        provider: str, evaluator: str, description: str, expired_at_hours: float = 24
    ) -> dict[str, Any]:
        job_id = arc.commerce.create_job(
            provider=provider,
            evaluator=evaluator,
            description=description,
            expired_at_hours=expired_at_hours,
        )
        return {"job_id": job_id, "client": arc.address}

    def _set_budget(job_id: int, amount_usdc: float) -> dict[str, Any]:
        receipt = arc.commerce.set_budget(job_id, amount_usdc)
        return {"job_id": job_id, "amount_usdc": amount_usdc, "tx": receipt["transactionHash"].hex()}

    def _fund_job(job_id: int) -> dict[str, Any]:
        receipt = arc.commerce.fund(job_id)
        return {"job_id": job_id, "tx": receipt["transactionHash"].hex()}

    def _submit(job_id: int, deliverable: str) -> dict[str, Any]:
        receipt = arc.commerce.submit(job_id, deliverable)
        return {"job_id": job_id, "tx": receipt["transactionHash"].hex()}

    def _complete(job_id: int, reason: str = "accepted") -> dict[str, Any]:
        receipt = arc.commerce.complete(job_id, reason)
        return {"job_id": job_id, "tx": receipt["transactionHash"].hex()}

    def _get_job(job_id: int) -> dict[str, Any]:
        job = arc.commerce.get_job(job_id)
        return {
            "id": job.id,
            "client": job.client,
            "provider": job.provider,
            "evaluator": job.evaluator,
            "description": job.description,
            "budget": job.budget,
            "expired_at": job.expired_at,
            "status": JobStatus(job.status).name,
            "hook": job.hook,
        }

    def _register_agent(metadata_uri: str) -> dict[str, Any]:
        agent_id = arc.identity.register(metadata_uri)
        return {"agent_id": agent_id, "owner": arc.address}

    return [
        StructuredTool.from_function(
            name="create_arc_job",
            description="Create a new ERC-8183 job on Arc. Returns the job ID.",
            func=_create_job,
            args_schema=CreateJobInput,
        ),
        StructuredTool.from_function(
            name="set_arc_budget",
            description="Set the budget for an ERC-8183 job in USDC. Caller must be the provider.",
            func=_set_budget,
            args_schema=SetBudgetInput,
        ),
        StructuredTool.from_function(
            name="fund_arc_job",
            description="Fund an ERC-8183 job. Auto-approves USDC. Caller must be the client.",
            func=_fund_job,
            args_schema=JobIdInput,
        ),
        StructuredTool.from_function(
            name="submit_arc_deliverable",
            description="Submit the deliverable for a job. Caller must be the provider.",
            func=_submit,
            args_schema=SubmitInput,
        ),
        StructuredTool.from_function(
            name="complete_arc_job",
            description="Accept a deliverable and release payment. Caller must be the evaluator.",
            func=_complete,
            args_schema=CompleteInput,
        ),
        StructuredTool.from_function(
            name="get_arc_job",
            description="Read the current state of an ERC-8183 job.",
            func=_get_job,
            args_schema=JobIdInput,
        ),
        StructuredTool.from_function(
            name="register_arc_agent",
            description="Register an agent identity on the ERC-8004 IdentityRegistry. Returns the new agent ID.",
            func=_register_agent,
            args_schema=RegisterAgentInput,
        ),
    ]
