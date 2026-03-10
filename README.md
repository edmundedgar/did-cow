# The did:cow Method Specification v0.1

**Status:** Draft Specification
**Date:** February 16, 2026

## Abstract

The `did:cow` method (Consensus Ownership Wrapper) provides a persistent, decentralized, censorship-proof wrapper around other DID methods.

It stores changes of control and migrations between wrapped DIDs on the Ethereum blockchain, providing strong anti-censorship and anti-reorg guarantees while avoiding the need to send blockchain transactions for initial account creation or day-to-day updates.

## Status of This Document

This is a draft specification and may be updated, replaced, or obsoleted at any time. It is inappropriate to cite this document as anything other than work in progress.

## 1. Introduction

### 1.1 Motivation

Existing DID methods have trade-offs:
- **did:key** - No rotation or recovery
- **did:web** - Domain dependency, if you lose control of your domain you lose control of your identity
- **did:plc** - Dependency on a centralized sequencer (Bluesky's PLC server)
- **did:ethr** - Gas costs for all updates

Migrating between methods breaks all existing references. `did:cow` provides a stable wrapper.

### 1.2 Design Goals

1. **Decentralized** - No central registry dependency
2. **Zero-cost creation** - No blockchain transaction to create
3. **Method agnostic** - Any DID method can be wrapped
4. **Transferable** - Controller can be changed
5. **Composable Control** - Automatic compatibility with multisig and decentralized organization tooling such as Gnosis Safe
6. **Minimal dependencies** - An Ethereum RPC endpoint is required to resolve, but you should not need other infrastructure such as an indexer.

## 2. DID Method Name

Method name: `cow` (Consensus Ownership Wrapper)

DID prefix: `did:cow:` (lowercase)

## 3. Method Specific Identifier

Format: `did:cow:<initial_controller_address>:<initial_wrapped_did>`

**Parameters:**
- `initial_controller_address` - Ethereum address (20 bytes, no "0x" prefix)
- `initial_wrapped_did` - The wrapped DID with its leading `did:` stripped, e.g. `web:example.com` rather than `did:web:example.com`

The `did:` prefix is omitted from the wrapped DID portion of the identifier because it is already implied by the DID syntax. This also reduces on-chain storage costs.

### 3.1 Example

```
initial_controller_address = "8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be"
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
2. Choose your initial controller address
3. Form the did:cow identifier by inserting `cow:<initial_controller_address>:` after the initial `did:`, and dropping the `did:` prefix from the wrapped DID

### 6.2 Read (Resolution)

1. Call `resolveCow(initial_controller_address, initial_wrapped_did)` on the registry contract
2. If no on-chain record exists, resolve the wrapped DID from the identifier directly
3. If an on-chain record exists, prepend `did:` to the returned wrapped DID value and resolve that
4. If the record is deactivated, return deactivated status

Resolved DID document includes the wrapped DID's content plus wrapper metadata.

### 6.3 Update

Send an on-chain transaction from the current controller to either:
- `updateWrappedDID` / `updateWrappedDIDByHash` — change the wrapped DID
- `updateController` / `updateControllerByHash` — transfer control to a new address

If the cow has not been registered on-chain yet, `updateWrappedDID` and `updateController` will register it automatically in the same transaction.

### 6.4 Deactivate

Permanent. On-chain transaction from current controller calling `deactivate(cowHash)`.

Sets the controller address to `0x0` and the stored wrapped DID to `:`.

After deactivation, the DID resolves to deactivated status and cannot be reactivated.

Note: It is permitted to set the controller to `0x0` via `updateController` without deactivating, in which case the DID continues to resolve but can never be updated or deactivated.

## 7. Security Considerations

### 7.1 Controller

The controller address inherits all the security considerations of any other Ethereum address. Addresses can be compromised by phishing, private key leakage etc.

### 7.2 Wrapped DID Dependence

The did:cow address inherits all security properties of wrapped DID.
- did:web → DNS hijacking risk
- did:key → no rotation
- did:plc → key compromise, trusted central party risk

However, since users can switch to another wrapped DID they can recover from a compromise of the wrapped DID, and also exit in circumstances where the wrapped DID appears unreliable.

### 7.3 Blockchain Dependencies

**Why Ethereum:**

High security, established ecosystem, established tooling for multisig and organizational control. Strong social consensus on anti-censorship means we can be confident that the main Ethereum chain, or failing that a viable fork of the Ethereum chain, will continue accepting updates without censorship for the foreseeable future.

**Tradeoffs:** Gas costs (25–100k gas per update depending on DID length and whether registration is included), ~12 second confirmation

## 8. Privacy Considerations

### 8.1 Controller Address Linkability

`controller_address` is visible as part of the DID and also on-chain once updates are made. Reusing a controller links all DIDs.

### 8.2 On-Chain Metadata

All updates permanently public with timestamps. Creates an audit trail of updates, previous/new wrapped DIDs, and controller history.

## 9. Reference Implementation

Deployed on Sepolia testnet: `0x8bd78c8CdCcF951169bbF964A0aCC241Be63B05f`

**Contract functions (`CowRegistry.sol`):**
- `calculateCowHash(controller, wrappedDID)` — derive the registry key for a cow
- `resolveCow(controller, wrappedDID)` — return current controller and wrapped DID without needing to pre-compute the hash
- `initializeCow(controller, wrappedDID)` — optionally pre-register before first update
- `updateWrappedDID(controller, wrappedDID, newWrappedDID)` — update wrapped DID, registering if needed
- `updateWrappedDIDByHash(cowHash, newWrappedDID)` — update wrapped DID by pre-computed hash
- `updateController(controller, wrappedDID, newController)` — transfer control, registering if needed
- `updateControllerByHash(cowHash, newController)` — transfer control by pre-computed hash
- `deactivate(cowHash)` — permanently deactivate

**CLI tool (`cli/cow.py`):**
- `resolve <did>` — resolve to current state and fetch wrapped DID document
- `update-wrapped <did> <newWrappedDID>` — update the wrapped DID
- `update-controller <did> <newController>` — transfer control
- `deactivate <did>` — permanently deactivate

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
  "id": "did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:web:example.com",
  "controller": "0x8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be",
  "verificationMethod": [
    {
      "id": "did:web:example.com#key-1",
      "type": "JsonWebKey2020",
      "controller": "did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:web:example.com",
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
        "wrapper_controller": "0x8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be",
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
| Zero-cost Updates | ✗ | ✓ | ✓ | ✓ |
| Decentralized | ✓ | ✓ | ✗ | ✗ |
| Blockchain Required | Ethereum | None | None | None |
| Rotation Authority | Ethereum | N/A | DNS | PLC Directory |
| Censorship Resistant | ✓ | ✓ | ✗ | ✗ |

## 12. Philosophical Considerations

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
