# The did:cow Method Specification v0.1

**Status:** Draft Specification

**Author:** Edmund Edgar ( [goat.navy](https://bsky.app/profile/goat.navy) )

**Date:** March 10th, 2026

## Abstract

The `did:cow` method (Consensus Ownership Wrapper) provides a persistent, decentralized, censorship-proof wrapper around other DID methods.

It stores changes of control and migrations between wrapped DIDs on the Ethereum blockchain, affording users strong anti-censorship and anti-reorg guarantees even if the wrapped DIDs lack these properties. 

It uses blockchain transactions for migration between DIDs and changes of control, but avoids the need for blockchain transactions for initial account creation or day-to-day updates.

## Status of This Document

This is a draft specification and may be updated, replaced, or obsoleted at any time. It is inappropriate to cite this document as anything other than work in progress.

## 1. Introduction

### 1.1 Motivation

Existing DID methods have trade-offs:
- **did:key** - No rotation or recovery.
- **did:web** - Domain dependency, if you lose control of your domain you lose control of your identity.
- **did:plc** - Dependency on a centralized sequencer (plc.directory) which can censor updates and/or create malicious reorgs.
- **did:ethr** - Gas costs for all updates.

Migration between DIDs is not possible, so your did:web identity only lasts as long as your control of your domain does, and your did:plc identity only lasts until the centralized did:plc starts acting dishonestly.

We propose that users continue to use these methods for day-to-day updates, but wrap them in a blockchain-managed identity to enable migration between them.

### 1.2 Design Goals

1. **Decentralized** - No trusted third-party responsible for ultimate resolution.
2. **Zero-cost creation** - No blockchain transaction should be required to create a did:cow ID.
3. **Method agnostic** - Any DID method can be wrapped.
4. **Transferable** - The controller used for a did:cow ID can be replaced. If using a smart contract as controller, the controller can be retained but access to the controller changed.
5. **Composable Control** - The controller can be an arbitrary computer program, allowing sophisticted custom logic and compatibility with multisig and decentralized organization tooling such as [Safe](https://docs.safe.global/home/what-is-safe).
6. **Minimal dependencies** - An Ethereum RPC endpoint is required to resolve, but you should not need additional infrastructure such as an indexer.

## 2. DID Method Name

Method name: `cow` (Consensus Ownership Wrapper)

DID prefix: `did:cow:` (lowercase)

## 3. Method Specific Identifier

Format: `did:cow:<initial_controller_address>:<initial_wrapped_did>`

**Parameters:**
- `initial_controller_address` - Ethereum address (20 bytes, no "0x" prefix)
- `initial_wrapped_did` - The wrapped DID with its leading `did:` stripped, e.g. `web:example.com` rather than `did:web:example.com`

### 3 Examples

### 3.1 An initial did:web ID

```
initial_controller_address = "8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be"
wrapped_did = "did:web:example.com"

DID = did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:web:example.com
```
### 3.2 An initial did:plc ID

```
initial_controller_address = "8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be"
wrapped_did = "did:plc:pyzlzqt6b2nyrha7smfry6rv"

DID = did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:plc:pyzlzqt6b2nyrha7smfry6rv
```

## 5. Blockchain Transactions

State mutations (updates/deactivations) are controlled by standard Ethereum calls made from the controller address. The controller can be an Externally Owned Account (controlled by a single cryptographic key) or a smart contract (controlled by multiple keys and/or custom logic).

1. A user sends a transaction either from the controller or calling the controller.
2. The did:cow registry contract validates: `msg.sender == current_controller`.
3. Either the state is updated or the transaction reverts.

## 6. CRUD Operations

### 6.1 Create

1. Create the DID you will wrap.
2. Choose your initial controller address.
3. Form the did:cow identifier by inserting `cow:<initial_controller_address>:` after the initial `did:`.

### 6.2 Read (Resolution)

Call `resolveCow(initial_controller_address, initial_wrapped_did)` against the registry contract.

 The did:cow registry contract performs the following steps:

 - If no on-chain record exists, resolve the wrapped DID from the identifier directly.
 - If an on-chain record exists, prepend `did:` to the returned wrapped DID value and resolve that.
 - If the record exists but has been deactivated, return deactivated status.

Resolve the wrapped DID as per that DID system's resolution method.

### 6.3 Update

Send an on-chain transaction from the current controller to either:
- `updateWrappedDID` / `updateWrappedDIDByHash` — change the wrapped DID
- `updateController` / `updateControllerByHash` — transfer control to a new address

If the cow has not been registered on-chain yet, `updateWrappedDID` and `updateController` will register it automatically in the same transaction.

### 6.4 Deactivate

An on-chain transaction from current controller calling `deactivate(cowHash)` permanently deactivates the did:cow ID.

It sets the controller address to `0x0` and the stored wrapped DID to `:`.

After deactivation, the DID resolves to deactivated status and cannot be reactivated.

NB: It is permitted to set the controller to `0x0` via `updateController` without deactivating, in which case the DID continues to resolve but can never be updated or deactivated.

## 7. Security Considerations

### 7.1 Controller

The controller address inherits all the security considerations of any other Ethereum address. Addresses can be compromised by phishing, private key leakage etc.

### 7.2 Wrapped DID Dependence

The did:cow address inherits the security risks of the wrapped DID:
- did:web: DNS hijacking risk
- did:key: no rotation ability
- did:plc: key compromise, risk of abuse by the trusted central server

However, since users can switch to another wrapped DID they can recover from a compromise of the wrapped DID, and also exit in circumstances where the wrapped DID appears likely to become unreliable in future.

### 7.3 Blockchain Dependencies

**Why Ethereum:**

Ethereum offers high security, an established ecosystem and well-supported tooling for multisig and organizational control. It also operates without needing proof-of-work, which many users dislike for its environmental impact.

Strong social consensus on anti-censorship means we can reasonably confident that the main Ethereum chain will continue accepting updates without censorship for the foreseeable future. We can also be highly confident that in the event that the dominant Ethereum chain lost this property, there would be a well-supported fork preserving its history that continued to have it.

**Trade-offs:** 

*Time until finality:* Updates typically take up to 12 seconds to confirm, and longer to finalize.

*Cost*: A system requiring consensus will typically have capacity limits. Systems aiming for censorship resistance cannot exercise discretion about which transactions are worthwhile, so they typically regulate usage by charging fees. Usage is unpredictable, so costs are also unpredictable: Although Ethereum gas prices are currently low, they may increase if usage grows faster than capacity, and may also be subject to sudden spikes. did:cow updates cost 40,000 to 100,000 gas per update depending on DID length and whether the account has already been registered on-chain. This is roughly equivalent to the cost of a transferring a token.

**Why only one chain:**

Some identity standards support multiple chains, for example by putting a Chain ID in the identifier. did:cow supports only a single chain, to avoid the additional complexity, the longer identifiers, and the requirement for resolvers to handle multiple RPC endpoints.

## 8. Privacy Considerations

### 8.1 Controller Address Linkability

`controller_address` is visible as part of the DID and also on-chain once updates are made. Reusing a controller links all DIDs.

### 8.2 On-Chain Metadata

All updates are permanently public with timestamps. This creates an audit trail of updates, previous/new wrapped DIDs, and controller history.

## 9. Reference Implementation

Deployed on Sepolia testnet: [`0x8bd78c8CdCcF951169bbF964A0aCC241Be63B05f`](https://sepolia.etherscan.io/address/0x8bd78c8CdCcF951169bbF964A0aCC241Be63B05f)

**Contract functions (`CowRegistry.sol`):**
- `calculateCowHash(controller, wrappedDID)` — derive the registry key for a cow
- `resolveCow(controller, wrappedDID)` — return current controller and wrapped DID without needing to pre-compute the hash
- `initializeCow(controller, wrappedDID)` — optionally pre-register before first update
- `updateWrappedDID(controller, wrappedDID, newWrappedDID)` — update wrapped DID, registering if needed
- `updateWrappedDIDByHash(cowHash, newWrappedDID)` — update wrapped DID by pre-computed hash
- `updateController(controller, wrappedDID, newController)` — transfer control, registering if needed
- `updateControllerByHash(cowHash, newController)` — transfer control by pre-computed hash
- `deactivate(controller, wrappedDID)` — permanently deactivate, registering if needed
- `deactivateByHash(cowHash)` — permanently deactivate by pre-computed hash

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

We consider this to illuminate a problem with the existing DIDs, rather than with this proposal. A permanent wrapper is required because users cannot be sufficiently confident in the permanence of their existing options.

## 13. References

- [DID Core Specification](https://www.w3.org/TR/did-core/)
- [DID Method Rubric](https://w3c.github.io/did-rubric/)
- [did:key Method](https://w3c-ccg.github.io/did-method-key/)
- [did:web Method](https://w3c-ccg.github.io/did-method-web/)
- [did:plc Method](https://github.com/did-method-plc/did-method-plc)

---

**Version History:**
- v0.1 (2026-02-16) - Initial draft specification
