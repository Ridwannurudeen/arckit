"""ERC-8004 IdentityRegistry client."""

from __future__ import annotations

from web3 import Web3

from arckit._tx import TxContext
from arckit.abi import IDENTITY_REGISTRY_ABI
from arckit.errors import AgentNotFoundError
from arckit.types import Agent


class IdentityClient:
    def __init__(self, ctx: TxContext, identity_registry_address: str):
        self._ctx = ctx
        self._contract = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(identity_registry_address),
            abi=IDENTITY_REGISTRY_ABI,
        )

    def owner_of(self, agent_id: int) -> str:
        try:
            return self._contract.functions.ownerOf(int(agent_id)).call()
        except Exception as exc:  # noqa: BLE001 — narrow to revert
            raise AgentNotFoundError(agent_id) from exc

    def token_uri(self, agent_id: int) -> str:
        return self._contract.functions.tokenURI(int(agent_id)).call()

    def balance_of(self, owner: str) -> int:
        return self._contract.functions.balanceOf(Web3.to_checksum_address(owner)).call()

    def get_agent(self, agent_id: int) -> Agent:
        return Agent(
            agent_id=agent_id,
            owner=self.owner_of(agent_id),
            metadata_uri=self.token_uri(agent_id),
        )

    def register(self, metadata_uri: str) -> int:
        receipt = self._ctx.send(self._contract.functions.register(metadata_uri))
        args = self._ctx.event_args(receipt, self._contract, "Transfer")
        if args is None:
            raise RuntimeError("Transfer event missing from receipt")
        return int(args["tokenId"])
