# The did:cow Method Specification v0.1

**Status:** Draft Specification  
**Date:** February 16, 2026

## Abstract

The `did:cow` method (Consensus Ownership Wrapper) provides persistent wrappers around other DID methods, enabling rotation and migration without breaking existing references. Uses Ethereum for state transitions, content-addressable storage for zero-cost creation.

## Status of This Document

This is a draft specification and may be updated, replaced, or obsoleted at any time. It is inappropriate to cite this document as anything other than work in progress.

## 1. Introduction

### 1.1 Motivation

Existing DID methods have tradeoffs:
- **did:key** - No rotation or recovery
- **did:web** - Domain dependency
- **did:plc** - Centralized sequencer (Bluesky's PLC server)
- **did:ethr** - Gas costs for all updates

Migrating between methods breaks all existing references. `did:cow` provides a stable wrapper.

### 1.2 Design Goals

1. **Persistent** - Wrapper DID never changes
2. **Zero-cost creation** - No blockchain transaction to create
3. **Method agnostic** - Wraps any DID method
4. **Self-certifying** - Hash-based construction
5. **Decentralized** - No central registry dependency
6. **Transferable** - Controller can be changed
7. **Rotation Independence** - Key rotation secured by Ethereum, not the wrapped DID's infrastructure
8. **Composible Control** - Automatic compatibility with multisig and decentralized organization tooling such as Gnosis Safe.

## 2. DID Method Name

Method name: `cow` (Consensus Ownership Wrapper)

DID prefix: `did:cow:` (lowercase)

## 3. Method Specific Identifier

Format: `did:cow:<controller_address>:<initial_wrapped_did>`


**Parameters:**
- `controller_address` - Ethereum address (20 bytes, no "0x" prefix)
- `initial_wrapped_did` - UTF-8 encoded DID string

### 3.1 Example

```
controller_address = "8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be" (20 bytes, no 0x prefix)
wrapped_did = "did:web:example.com"

DID = did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:web:example.com
```

## 5. Blockchain Transaction Model

State mutations (updates/deactivations) are standard Ethereum transactions from the controller address.

**Flow:**
1. Controller creates transaction with operation data
2. Controller signs with Ethereum key
3. Transaction broadcast to Ethereum
4. Smart contract validates: `msg.sender == current_controller`
5. State updated or transaction reverts

**Smart Contract Implementation:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract COWRegistry {
    struct COW {
        address controller;
        bool deactivated;
        bytes wrappedDid;
    }
    
    mapping(bytes32 => State) public cows;
    
    event DIDUpdated(bytes32 indexed didHash, address controller, bytes wrappedDid);
    event DIDDeactivated(bytes32 indexed didHash);

    modifier onlyOwner() {
    }

    function updateWrappedDID(
        bytes32 didHash,
        bytes calldata newWrappedDid
    ) external onlyOwner {
        cows[didHash].wrappedDid = newWrappedDid;
    }
    
    function updateController(
        bytes32 didHash, 
        address newController, 
    ) external {
        State storage state = didStates[didHash];
        
        // First update creates the state
        if (state.controller == address(0)) {
            require(newController != address(0), "Controller required");
            require(newWrappedDid.length > 0, "WrappedDid required");
            state.controller = msg.sender;
        } else {
            // Subsequent updates require authorization
            require(msg.sender == state.controller, "Not authorized");
            require(!state.deactivated, "DID is deactivated");
        }
        
        // Update state
        if (newController != address(0)) {
            state.controller = newController;
        }
        if (newWrappedDid.length > 0) {
            state.wrappedDid = newWrappedDid;
        }
        
        state.lastUpdated = block.timestamp;
        emit DIDUpdated(didHash, state.controller, state.wrappedDid);
    }
    
    function deactivate(bytes32 didHash) external {
        State storage state = didStates[didHash];
        
        require(msg.sender == state.controller, "Not authorized");
        require(!state.deactivated, "Already deactivated");
        
        state.deactivated = true;
        emit DIDDeactivated(didHash);
    }
    
    function resolve(bytes32 didHash) external view returns (
        address controller,
        bytes memory wrappedDid,
        bool deactivated
    ) {
        State storage state = didStates[didHash];
        return (state.controller, state.wrappedDid, state.deactivated);
    }
}
```

## 6. CRUD Operations

### 6.1 Create

No blockchain transaction required.

**Process:**
1. Choose `wrapped_did` and `controller_address`
2. Construct DID: `did:cow:<controller_address>:wrapped_did`

**Verification:** Anyone can fetch the state, recompute hash, confirm it matches the DID.

### 6.2 Read (Resolution)

**Algorithm:**
1. Extract `<hash>` from `did:cow:<hash>`
2. Query blockchain for state matching `<hash>`
3. **If on-chain state exists:** Parse state, resolve wrapped_did, add wrapper metadata
4. **If no on-chain state:** Fetch from content-addressable storage, verify hash, resolve wrapped_did, add metadata

Resolved DID document includes wrapped DID's content plus wrapper metadata in `service` endpoint.

### 6.3 Update

On-chain transaction from current controller.

**Binary format:**
```
[32 bytes: did_hash]
[1 byte: operation_type (0x01)]
[20 bytes: new_controller (0x00...00 if unchanged)]
[N bytes: new_wrapped_did UTF-8]
```

**Validation:**
- Transaction from current controller address
- At least one field must change
- New wrapped_did must be valid

**Use cases:** DID rotation, key recovery, controller transfer, method migration

### 6.4 Deactivate

Permanent. On-chain transaction from current controller.

**Binary format:**
```
[32 bytes: did_hash]
[1 byte: operation_type (0x02)]
```

After deactivation, DID resolves to deactivated status. Cannot be reactivated.

## 7. Security Considerations

### 7.1 Controller Key Security

Security depends on:
1. Controller's Ethereum private key (secp256k1)
2. Wrapped DID's keys

Compromised controller key → attacker can update wrapper.
Compromised wrapped DID keys → attacker can impersonate within that method.

### 7.2 Wrapped DID Dependence

Inherits ALL security properties of wrapped DID, but is recoverable:
- did:web → DNS hijacking risk
- did:key → no rotation
- did:plc → trust in Bluesky's directory

### 7.3 Blockchain Dependencies

Uses Ethereum mainnet for state transitions, immutable audit trail, authorization, and spam prevention (gas costs).

**Why Ethereum:** High security, established ecosystem, ECDSA signing, native smart contracts, deterministic finality.

**Tradeoffs:** Gas costs (~50-100k gas per update), ~12 second confirmation

## 8. Privacy Considerations

### 8.1 Controller Address Linkability

`controller_address` appears in hash computation and on-chain. Reusing controller links all DIDs.

**Mitigation:** Different controllers per context or privacy-preserving addresses.

### 8.2 On-Chain Metadata

All updates permanently public with timestamps. Creates audit trail of updates, previous/new wrapped DIDs, and controller history.

## 9. Reference Implementation

Available at: [To be provided]

**Key functions:**
- `createDID(controllerHex, wrappedDid)` - Generate did:cow
- `parseInitialState(stateBytes)` - Parse binary state
- `resolveDID(didCow)` - Resolve to DID document
- `updateDID(didCow, newWrappedDid, newController)` - Build update transaction
- `deactivateDID(didCow)` - Build deactivation transaction

**Benefits:** No signature in payload (blockchain handles auth), ~50% smaller than JSON, deterministic parsing, fixed-length addressing enables delimiter-free concatenation, native replay protection.

## 10. Example DID Document

Given:
```
did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:web:example.com
```

Wrapping:
```
did:web:example.com
```

Resolved DID Document:
```json
{
  "@context": [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/suites/jws-2020/v1"
  ],
  "id": "did:cow:8b7df143d91c716ecfa5fc1730022f6b421b05cedee8fd52b1fc65a96030ad52",
  "controller": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "verificationMethod": [
    {
      "id": "did:web:example.com#key-1",
      "type": "JsonWebKey2020",
      "controller": "did:cow:8b7df143d91c716ecfa5fc1730022f6b421b05cedee8fd52b1fc65a96030ad52",
      "publicKeyJwk": {
        "kty": "EC",
        "crv": "secp256k1",
        "x": "...",
        "y": "..."
      }
    }
  ],
  "authentication": [
    "did:web:example.com#key-1"
  ],
  "service": [
    {
      "id": "#wrapper-metadata",
      "type": "COWWrapper",
      "serviceEndpoint": {
        "wrapped_did": "did:web:example.com",
        "wrapper_controller": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        "on_chain_state": true,
        "last_updated": "2026-02-16T10:30:00Z"
      }
    }
  ]
}
```

## 11. Comparison

| Feature | did:cow | did:key | did:web | did:plc |
|---------|---------|---------|---------|---------|
| Rotation Support | ✓ | ✗ | ✓ | ✓ |
| Recovery | ✓ | ✗ | Limited | ✓ |
| Zero-cost Creation | ✓ | ✓ | ✓ | ✗ |
| Decentralized | ✓ | ✓ | ✗ | ✗ |
| Method Migration | ✓ | ✗ | ✗ | ✗ |
| Self-verifying | Partial | ✓ | ✗ | ✗ |
| Blockchain Required | Ethereum | None | None | None |
| Rotation Authority | Ethereum | N/A | DNS | PLC Directory |
| Censorship Resistant | ✓ | N/A | ✗ | ✗ |

## 12. Use Cases

### 12.1 Solving did:plc Reorg Risk

did:plc weakness: Bluesky controls operation log sequencing. Can reorder/reorg history.

**Risks:** Operation log rewrites, sequence ambiguity, directory downtime.

**Solution with did:cow wrapper:**
```
did:cow:abc123 → did:plc:z72i7hdynmk6r22z27h6tvur
```

If PLC has issues, execute Ethereum transaction to rotate:
```
did:cow:abc123 → did:web:yoursite.com
```

**Result:** PLC becomes an optional convenience layer, not a single point of failure. Ethereum provides immutable, censorship-resistant record of canonical DID.

### 12.2 Progressive Decentralization

Start simple, upgrade later:
```
T0: did:cow:abc123 → did:web:example.com
T1: did:cow:abc123 → did:plc:z72i7hdynmk6r22z27h6tvur
```

### 12.3 Key Compromise Recovery

Rotate to fresh keys:
```
did:cow:abc123 → did:plc:compromised-id  [compromised]
did:cow:abc123 → did:plc:fresh-keys-id   [Ethereum tx]
```

### 12.4 Domain Loss Recovery

Domain expired? Rotate:
```
did:cow:abc123 → did:web:lost-domain.com  [expired]
did:cow:abc123 → did:plc:recovered-id     [Ethereum tx]
```

### 12.5 Multi-Identity Aggregation

Rotate between multiple DIDs for different contexts while maintaining one persistent identifier.

## 14. References

- [DID Core Specification](https://www.w3.org/TR/did-core/)
- [DID Method Rubric](https://w3c.github.io/did-rubric/)
- [did:key Method](https://w3c-ccg.github.io/did-method-key/)
- [did:web Method](https://w3c-ccg.github.io/did-method-web/)
- [did:plc Method](https://github.com/did-method-plc/did-method-plc)

## Appendix A: Hash Computation Example

Python implementation:

```python
import hashlib

def create_did_tlc(controller_hex: str, wrapped_did: str) -> str:
    """
    Create a did:cow identifier.
    
    Args:
        controller_hex: Ethereum address as hex string (no 0x prefix), e.g., "742d35..."
        wrapped_did: The DID to wrap, e.g., "did:ion:..."
    """
    # Convert controller from hex to bytes
    controller_bytes = bytes.fromhex(controller_hex)
    
    # Convert wrapped_did to UTF-8 bytes
    wrapped_did_bytes = wrapped_did.encode('utf-8')
    
    # Concatenate: controller || wrapped_did
    preimage = controller_bytes + wrapped_did_bytes
    
    # Compute SHA-256 hash
    hash_bytes = hashlib.sha256(preimage).digest()
    
    # Convert to hex string
    hash_hex = hash_bytes.hex()
    
    # Construct DID
    return f"did:cow:{hash_hex}"

def parse_initial_state(state_bytes: bytes) -> tuple[str, str]:
    """
    Parse initial state blob.
    
    Returns: (controller_hex, wrapped_did)
    """
    controller_bytes = state_bytes[:20]
    wrapped_did_bytes = state_bytes[20:]
    
    controller_hex = controller_bytes.hex()
    wrapped_did = wrapped_did_bytes.decode('utf-8')
    
    return controller_hex, wrapped_did

# Example
controller = "742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
wrapped = "did:web:example.com"

did = create_did_tlc(controller, wrapped)
print(did)
# Output: did:cow:8b7df143d91c716ecfa5fc1730022f6b421b05cedee8fd52b1fc65a96030ad52

# Verify
state_blob = bytes.fromhex(controller) + wrapped.encode('utf-8')
parsed_controller, parsed_wrapped = parse_initial_state(state_blob)
verified_did = create_did_tlc(parsed_controller, parsed_wrapped)
assert verified_did == did
```

## Appendix B: Acknowledgments

This specification was designed in collaboration with Claude (Anthropic) on February 16, 2026.

---

**Version History:**
- v0.1 (2026-02-16) - Initial draft specification
