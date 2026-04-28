"""Tests for arckit.constants."""

import pytest

from arckit.constants import TESTNET_ADDRESSES, USDC_DECIMALS, get_network_config


def test_testnet_addresses_match_canonical_arc():
    assert TESTNET_ADDRESSES["agentic_commerce"] == "0x0747EEf0706327138c69792bF28Cd525089e4583"
    assert TESTNET_ADDRESSES["identity_registry"] == "0x8004A818BFB912233c491871b3d84c89A494BD9e"
    assert TESTNET_ADDRESSES["reputation_registry"] == "0x8004B663056A597Dffe9eCcC1965A193B7388713"
    assert TESTNET_ADDRESSES["validation_registry"] == "0x8004Cb1BF31DAf7788923b405b754f57acEB4272"
    assert TESTNET_ADDRESSES["usdc"] == "0x3600000000000000000000000000000000000000"


def test_usdc_decimals_is_six():
    assert USDC_DECIMALS == 6


def test_get_network_config_testnet():
    config = get_network_config("testnet")
    assert config["chain_id"] == 5042002
    assert config["rpc"].startswith("https://")
    assert "addresses" in config


def test_get_network_config_unknown_raises():
    with pytest.raises(ValueError, match="Unknown network"):
        get_network_config("mainnet-not-yet")
