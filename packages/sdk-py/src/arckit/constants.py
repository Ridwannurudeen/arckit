"""Network and contract address constants for Arc."""

ARC_TESTNET_CHAIN_ID = 5042002
ARC_TESTNET_RPC = "https://rpc.testnet.arc.network"
ARC_TESTNET_EXPLORER = "https://testnet.arcscan.app"

USDC_DECIMALS = 6

# Canonical Arc testnet contract addresses
TESTNET_ADDRESSES = {
    "agentic_commerce": "0x0747EEf0706327138c69792bF28Cd525089e4583",
    "identity_registry": "0x8004A818BFB912233c491871b3d84c89A494BD9e",
    "reputation_registry": "0x8004B663056A597Dffe9eCcC1965A193B7388713",
    "validation_registry": "0x8004Cb1BF31DAf7788923b405b754f57acEB4272",
    "usdc": "0x3600000000000000000000000000000000000000",
}

NETWORKS = {
    "testnet": {
        "chain_id": ARC_TESTNET_CHAIN_ID,
        "rpc": ARC_TESTNET_RPC,
        "explorer": ARC_TESTNET_EXPLORER,
        "addresses": TESTNET_ADDRESSES,
    },
}


def get_network_config(network: str) -> dict:
    if network not in NETWORKS:
        raise ValueError(f"Unknown network: {network}. Known: {list(NETWORKS.keys())}")
    return NETWORKS[network]
