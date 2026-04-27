"""ERC-8004 ValidationRegistry client."""

from __future__ import annotations

from web3 import Web3

from arckit._tx import TxContext
from arckit.abi import VALIDATION_REGISTRY_ABI
from arckit.types import ValidationResponse, ValidationStatus
from arckit.utils import hash_string


class ValidationClient:
    def __init__(self, ctx: TxContext, validation_registry_address: str):
        self._ctx = ctx
        self._contract = ctx.w3.eth.contract(
            address=Web3.to_checksum_address(validation_registry_address),
            abi=VALIDATION_REGISTRY_ABI,
        )

    def get_validation_status(self, request_hash: bytes) -> ValidationStatus:
        raw = self._contract.functions.getValidationStatus(request_hash).call()
        return ValidationStatus(
            validator_address=raw[0],
            agent_id=raw[1],
            response=ValidationResponse(raw[2]),
            response_hash=raw[3],
            tag=raw[4],
            last_update=raw[5],
        )

    def validation_request(
        self,
        validator: str,
        agent_id: int,
        request_uri: str,
        request_hash: bytes | None = None,
    ) -> dict:
        if request_hash is None:
            request_hash = hash_string(request_uri)
        return self._ctx.send(
            self._contract.functions.validationRequest(
                Web3.to_checksum_address(validator),
                int(agent_id),
                request_uri,
                request_hash,
            )
        )

    def validation_response(
        self,
        request_hash: bytes,
        response: ValidationResponse,
        response_uri: str,
        tag: str = "",
        response_hash: bytes | None = None,
    ) -> dict:
        if response_hash is None:
            response_hash = hash_string(response_uri)
        return self._ctx.send(
            self._contract.functions.validationResponse(
                request_hash,
                int(response),
                response_uri,
                response_hash,
                tag,
            )
        )
