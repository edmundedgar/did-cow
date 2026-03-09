# The did:cow Method Specification v0.1

**Status:** Draft Specification  
**Date:** February 16, 2026

## Abstract

The `did:cow` method (Consensus Ownership Wrapper) provides persistent wrappers around other DID methods, enabling rotation and migration without breaking existing references. 
It stores changes of control (done currently done with `rotationKeys` in DID:PLC) on the Ethereum blockchain.

## Status of This Document

This is a draft specification and may be updated, replaced, or obsoleted at any time. It is inappropriate to cite this document as anything other than work in progress.

## 1. Introduction

### 1.1 Motivation

Existing DID methods have tradeoffs:
- **did:key** - No rotation or recovery
- **did:web** - Domain dependency, if you lose control of your domain you lose control of your identity
- **did:plc** - Dependency on a centralized sequencer (Bluesky's PLC server)
- **did:ethr** - Gas costs for all updates

Migrating between methods breaks all existing references. `did:cow` provides a stable wrapper.

### 1.2 Design Goals

1. **Persistent** - Wrapper DID never changes
2. **Zero-cost creation** - No blockchain transaction to create
3. **Method agnostic** - Wraps any DID method
4. **Decentralized** - No central registry dependency
5. **Transferable** - Controller can be changed
6. **Composible Control** - Automatic compatibility with multisig and decentralized organization tooling such as Gnosis Safe.

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

1. Controller creates transaction with operation data
2. Controller signs with Ethereum key
3. Transaction broadcast to Ethereum
4. Smart contract validates: `msg.sender == current_controller`
5. State updated or transaction reverts

## 6. CRUD Operations

### 6.1 Create

1. Create the wrapped DID
2. Choose your controller address
2. Insert `cow:<controller_address>:` after the initial `did`:.

### 6.2 Read (Resolution)

1. Query an Ethereum RPC endpoint to find out the wrapped DID
2. If it returns a value, resolve that as per that DID's standard
3. If it is unset, use the DID value originally specified in the ID

Resolved DID document includes wrapped DID's content plus wrapper metadata.

### 6.3 Update

Make an on-chain transaction from the current controller.

The initial update

### 6.4 Deactivate

Permanent. On-chain transaction from current controller.

Set the controller address to `0x` and the wrapped DID value to `did:`.

After deactivation, DID resolves to deactivated status. Cannot be reactivated.

## 7. Security Considerations

### 7.1 Controller

The controller address inherits all the security considerations of any other Ethereum address. 

### 7.2 Wrapped DID Dependence

The did:cow address inherits all security properties of wrapped DID.
- did:web → DNS hijacking risk
- did:key → no rotation
- did:plc → trust in Bluesky's directory

However, since users can switch to another wrapped DID they can recover a compromise of the wrapped DID, and also exit in circumstances where the wrapped DID appears unreliable.

### 7.3 Blockchain Dependencies

**Why Ethereum:** 

High security, established ecosystem, established tooling for multisig and organizational control. Strong social consensus on anti-censorship means we can be confident that the main Ethereum chain, or failing that a viable fork of the Ethereum chain, will accept continue accepting updates without censorship for the foreseeable future.

**Tradeoffs:** Gas costs (~50-100k gas per update), ~12 second confirmation

## 8. Privacy Considerations

### 8.1 Controller Address Linkability

`controller_address` is visible as part of the DID and also on-chain once updates are made. Reusing a controller links all DIDs.

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
| Zero-cost Creation | ✓ | ✓ | ✓ | ✓ |
| Zero-cost Controller Updates | ✗  | ✓ | ✓ | ✓ |
| Decentralized | ✓ | ✓ | ✗ | ✗ |
| Zero-cost Controller Updates | ✓ | ✓ | ✓ | ✓ |
| Decentralized | ✓ | ✓ | ✗ | ✗ |
| Blockchain Required | Ethereum | None | None | None |
| Rotation Authority | Ethereum | N/A | DNS | PLC Directory |
| Censorship Resistant | ✓ | ✓  | ✗ | ✗ |

## 12. Philosophical considerations

DIDs are intended to be permanent identifiers. Using a wrapper implies that the wrapped DID is not in fact a permanent identifier.

We consider this to illuminate a problem with the wrapped DIDs, rather than with this proposal. A permanent wrapper is required because users cannot be sufficiently confident in the permanence of their existing options.

## 13. References

- [DID Core Specification](https://www.w3.org/TR/did-core/)
- [DID Method Rubric](https://w3c.github.io/did-rubric/)
- [did:key Method](https://w3c-ccg.github.io/did-method-key/)
- [did:web Method](https://w3c-ccg.github.io/did-method-web/)
- [did:plc Method](https://github.com/did-method-plc/did-method-plc)

---

**Version History:**
- v0.1 (2026-02-16) - Initial draft specification
