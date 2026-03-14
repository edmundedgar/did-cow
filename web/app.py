#!/usr/bin/env python3
"""did:cow resolution API"""

import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from web3 import Web3

# Load env and import helpers from CLI
load_dotenv(Path(__file__).parent.parent / "cli" / ".env")
sys.path.insert(0, str(Path(__file__).parent.parent / "cli"))
from cow import _controller_address, _parse_cow_did, _resolve_did_doc, _strip_did_prefix

_ABI_PATH = Path(__file__).parent.parent / "out" / "CowRegistry.sol" / "CowRegistry.json"


def _get_contract():
    url = os.getenv("RPC_URL")
    addr = os.getenv("CONTRACT_ADDRESS")
    if not url or not addr:
        raise RuntimeError("RPC_URL and CONTRACT_ADDRESS must be set")
    w3 = Web3(Web3.HTTPProvider(url))
    artifact = json.loads(_ABI_PATH.read_text())
    contract = w3.eth.contract(
        address=Web3.to_checksum_address(addr),
        abi=artifact["abi"],
    )
    return w3, contract


app = FastAPI(title="did:cow resolver", docs_url="/api/docs", redoc_url=None)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


def _validate_cow_did(did: str):
    """Parse and validate a did:cow DID, raising HTTPException on failure."""
    try:
        return _parse_cow_did(did)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/{did:path}/describe")
async def describe(did: str):
    """Return on-chain state for a did:cow DID without fetching the wrapped DID document."""
    controller_hex, initial_wrapped = _validate_cow_did(did)
    w3, contract = _get_contract()
    controller_addr = _controller_address(controller_hex)

    wrapped_did, controller = contract.functions.resolve(controller_addr, initial_wrapped).call()

    if wrapped_did == "":
        return {"status": "deactivated"}

    cow_hash = contract.functions.calculateHash(controller_addr, initial_wrapped).call()
    registered = contract.functions.cows(cow_hash).call()[1]  # initialized bool

    return {
        "status": "active" if registered else "not registered on-chain",
        "wrappedDid": wrapped_did,
        "controller": controller,
    }


@app.get("/{did:path}")
async def resolve_did(did: str):
    """Resolve a did:cow DID and return the modified DID document."""
    controller_hex, initial_wrapped = _validate_cow_did(did)
    w3, contract = _get_contract()
    controller_addr = _controller_address(controller_hex)

    wrapped_did, controller = contract.functions.resolve(controller_addr, initial_wrapped).call()

    if wrapped_did == "":
        raise HTTPException(status_code=404, detail="DID is deactivated")

    try:
        _, doc = _resolve_did_doc(_strip_did_prefix(wrapped_did))
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))

    chain_id = w3.eth.chain_id
    doc["id"] = did
    doc["did:cow"] = {
        "controller": f"did:pkh:eip155:{chain_id}:{controller}",
        "wrappedDid": wrapped_did,
    }

    return JSONResponse(content=doc)
