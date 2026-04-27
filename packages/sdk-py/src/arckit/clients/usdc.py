"""USDC (ERC-20) client."""

from __future__ import annotations

from web3 import Web3

from arckit._tx import TxContext
from arckit.abi import ERC20_ABI
from arckit.utils import from_usdc_base, to_usdc_base


class UsdcClient:
    def __init__(self, ctx: TxContext, usdc_address: str):
        self._ctx = ctx
        self._contract = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(usdc_address), abi=ERC20_ABI
        )

    def balance_of_raw(self, account: str) -> int:
        return self._contract.functions.balanceOf(Web3.to_checksum_address(account)).call()

    def balance_of(self, account: str) -> float:
        return from_usdc_base(self.balance_of_raw(account))

    def allowance(self, owner: str, spender: str) -> int:
        return self._contract.functions.allowance(
            Web3.to_checksum_address(owner), Web3.to_checksum_address(spender)
        ).call()

    def approve(self, spender: str, amount: float | int) -> dict:
        return self._ctx.send(
            self._contract.functions.approve(
                Web3.to_checksum_address(spender), to_usdc_base(amount)
            )
        )

    def transfer(self, to: str, amount: float | int) -> dict:
        return self._ctx.send(
            self._contract.functions.transfer(Web3.to_checksum_address(to), to_usdc_base(amount))
        )
