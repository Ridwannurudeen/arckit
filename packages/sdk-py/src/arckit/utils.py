"""Shared helpers for ArcKit clients."""

from web3 import Web3

from arckit.constants import USDC_DECIMALS


def to_usdc_base(amount: float | int) -> int:
    """Convert a USDC amount (e.g. 1.5) to base units (6 decimals)."""
    if isinstance(amount, int) and not isinstance(amount, bool):
        return amount
    return round(float(amount) * 10**USDC_DECIMALS)


def from_usdc_base(amount: int) -> float:
    """Convert USDC base units back to a float."""
    return amount / 10**USDC_DECIMALS


def hash_string(s: str) -> bytes:
    """keccak256 of a UTF-8 string. Returns 32-byte digest."""
    return Web3.keccak(text=s)
