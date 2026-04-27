"""Tests for arckit.utils."""

from arckit.utils import from_usdc_base, hash_string, to_usdc_base


def test_to_usdc_base_with_int():
    assert to_usdc_base(1) == 1
    assert to_usdc_base(1_000_000) == 1_000_000


def test_to_usdc_base_with_float():
    assert to_usdc_base(1.0) == 1_000_000
    assert to_usdc_base(1.5) == 1_500_000
    assert to_usdc_base(0.000001) == 1


def test_to_usdc_base_rounds():
    # 0.1 + 0.2 == 0.30000000000000004 in float; rounding handles it
    assert to_usdc_base(0.1 + 0.2) == 300_000


def test_from_usdc_base():
    assert from_usdc_base(1_000_000) == 1.0
    assert from_usdc_base(2_500_000) == 2.5
    assert from_usdc_base(0) == 0


def test_hash_string_deterministic():
    h1 = hash_string("hello world")
    h2 = hash_string("hello world")
    assert h1 == h2
    assert len(h1) == 32


def test_hash_string_different_inputs():
    assert hash_string("a") != hash_string("b")
