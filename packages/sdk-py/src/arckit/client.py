"""ArcKit — top-level synchronous client."""

from __future__ import annotations

from eth_account import Account
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware

from arckit._tx import TxContext
from arckit.clients import CommerceClient, IdentityClient, ReputationClient, UsdcClient, ValidationClient
from arckit.constants import get_network_config


class ArcKit:
    """Composable client for Arc agent commerce.

    Args:
        private_key: Hex private key for write operations. Omit for read-only.
        network: Network preset (default 'testnet').
        rpc_url: Override the network's RPC endpoint.
        addresses: Override individual contract addresses (dict keys: agentic_commerce,
            identity_registry, reputation_registry, validation_registry, usdc).
        tx_timeout: Seconds to wait for transaction confirmation (default 120).
    """

    def __init__(
        self,
        private_key: str | None = None,
        network: str = "testnet",
        rpc_url: str | None = None,
        addresses: dict | None = None,
        tx_timeout: int = 120,
    ):
        config = get_network_config(network)
        rpc = rpc_url or config["rpc"]

        self.w3 = Web3(Web3.HTTPProvider(rpc))
        self.w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
        self.chain_id = config["chain_id"]

        self.account = Account.from_key(private_key) if private_key else None

        addr = {**config["addresses"], **(addresses or {})}
        self.addresses = addr

        ctx = TxContext(
            w3=self.w3,
            account=self.account,
            chain_id=self.chain_id,
            tx_timeout=tx_timeout,
        )
        self._ctx = ctx

        self.commerce = CommerceClient(ctx, addr["agentic_commerce"], addr["usdc"])
        self.identity = IdentityClient(ctx, addr["identity_registry"])
        self.reputation = ReputationClient(ctx, addr["reputation_registry"])
        self.validation = ValidationClient(ctx, addr["validation_registry"])
        self.usdc = UsdcClient(ctx, addr["usdc"])

    @property
    def address(self) -> str | None:
        return self.account.address if self.account else None
