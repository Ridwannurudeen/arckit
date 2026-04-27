"""Typed data classes mirroring on-chain ERC-8183 / ERC-8004 structs."""

from dataclasses import dataclass
from enum import IntEnum


class JobStatus(IntEnum):
    OPEN = 0
    FUNDED = 1
    SUBMITTED = 2
    COMPLETED = 3
    REJECTED = 4
    EXPIRED = 5


class FeedbackCategory(IntEnum):
    QUALITY = 0
    RELIABILITY = 1
    SPEED = 2
    COMMUNICATION = 3
    OTHER = 4


class ValidationResponse(IntEnum):
    PENDING = 0
    APPROVED = 1
    REJECTED = 2


@dataclass
class Job:
    id: int
    client: str
    provider: str
    evaluator: str
    description: str
    budget: int
    expired_at: int
    status: JobStatus
    hook: str


@dataclass
class Agent:
    agent_id: int
    owner: str
    metadata_uri: str


@dataclass
class Feedback:
    agent_id: int
    from_address: str
    score: int
    feedback_type: FeedbackCategory
    feedback_hash: str


@dataclass
class ValidationStatus:
    validator_address: str
    agent_id: int
    response: ValidationResponse
    response_hash: str
    tag: str
    last_update: int
