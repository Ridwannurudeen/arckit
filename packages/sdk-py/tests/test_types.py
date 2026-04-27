"""Tests for arckit.types."""

from arckit.types import Agent, FeedbackCategory, Job, JobStatus, ValidationResponse


def test_job_status_values():
    assert JobStatus.OPEN == 0
    assert JobStatus.FUNDED == 1
    assert JobStatus.SUBMITTED == 2
    assert JobStatus.COMPLETED == 3
    assert JobStatus.REJECTED == 4
    assert JobStatus.EXPIRED == 5


def test_feedback_category_values():
    assert FeedbackCategory.QUALITY == 0
    assert FeedbackCategory.OTHER == 4


def test_validation_response_values():
    assert ValidationResponse.PENDING == 0
    assert ValidationResponse.APPROVED == 1
    assert ValidationResponse.REJECTED == 2


def test_job_dataclass_construction():
    job = Job(
        id=1,
        client="0x0",
        provider="0x1",
        evaluator="0x2",
        description="audit",
        budget=1_000_000,
        expired_at=99,
        status=JobStatus.OPEN,
        hook="0x3",
    )
    assert job.id == 1
    assert job.status == JobStatus.OPEN


def test_agent_dataclass_construction():
    a = Agent(agent_id=42, owner="0xabc", metadata_uri="ipfs://x")
    assert a.agent_id == 42
    assert a.metadata_uri == "ipfs://x"
