"""Tests for ArcKit construction and wallet-required guards.

These tests don't hit the network — they verify constructor wiring and that
write methods refuse to run without a private key.
"""

import pytest

from arckit import ArcKit, WalletRequiredError
from arckit.constants import TESTNET_ADDRESSES
from arckit.types import FeedbackCategory

TEST_PRIVATE_KEY = "0x" + "01" * 32


def _build(read_only: bool = True) -> ArcKit:
    if read_only:
        return ArcKit(network="testnet")
    return ArcKit(private_key=TEST_PRIVATE_KEY, network="testnet")


def test_arckit_read_only_construction():
    arc = _build(read_only=True)
    assert arc.account is None
    assert arc.address is None


def test_arckit_with_private_key():
    arc = _build(read_only=False)
    assert arc.account is not None
    assert arc.address is not None
    # eth_account derives address from private_key=01*32 deterministically
    assert arc.address == "0x1a642f0E3c3aF545E7AcBD38b07251B3990914F1"


def test_arckit_uses_testnet_addresses_by_default():
    arc = _build()
    assert arc.addresses == TESTNET_ADDRESSES


def test_arckit_address_overrides():
    arc = ArcKit(
        network="testnet",
        addresses={"agentic_commerce": "0x000000000000000000000000000000000000dEaD"},
    )
    assert arc.addresses["agentic_commerce"] == "0x000000000000000000000000000000000000dEaD"
    # Other addresses remain at testnet defaults
    assert arc.addresses["identity_registry"] == TESTNET_ADDRESSES["identity_registry"]


def test_arckit_exposes_all_subclients():
    arc = _build()
    assert arc.commerce is not None
    assert arc.identity is not None
    assert arc.reputation is not None
    assert arc.validation is not None
    assert arc.usdc is not None


def test_commerce_create_job_without_wallet_raises():
    arc = _build(read_only=True)
    with pytest.raises(WalletRequiredError):
        arc.commerce.create_job(
            provider="0x0000000000000000000000000000000000000001",
            evaluator="0x0000000000000000000000000000000000000002",
            expired_at_hours=24,
            description="test",
        )


def test_identity_register_without_wallet_raises():
    arc = _build(read_only=True)
    with pytest.raises(WalletRequiredError):
        arc.identity.register("ipfs://x")


def test_reputation_give_feedback_without_wallet_raises():
    arc = _build(read_only=True)
    with pytest.raises(WalletRequiredError):
        arc.reputation.give_feedback(
            agent_id=1, score=50, feedback_type=FeedbackCategory.QUALITY
        )


def test_usdc_approve_without_wallet_raises():
    arc = _build(read_only=True)
    with pytest.raises(WalletRequiredError):
        arc.usdc.approve("0x0000000000000000000000000000000000000001", 1)


def test_create_job_requires_expiry_arg():
    arc = _build(read_only=False)
    with pytest.raises(ValueError, match="Pass either expired_at"):
        arc.commerce.create_job(
            provider="0x0000000000000000000000000000000000000001",
            evaluator="0x0000000000000000000000000000000000000002",
            description="test",
        )
