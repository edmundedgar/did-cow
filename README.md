# The did:cow method specification

Status: Draft Specification<br>
Author: Edmund Edgar ( [goat.navy](https://bsky.app/profile/goat.navy) )<br>
Date: March 10th, 2026

## Abstract

The `did:cow` method (Consensus Ownership Wrapper) provides a persistent, decentralized, censorship-proof wrapper around other DID methods.

It stores changes of control and migrations between wrapped DIDs on the Ethereum blockchain, affording users strong anti-censorship and anti-reorg guarantees and allows recovery even if the centralized server or domain used by a did:plc or did:web ID is compromised.

It uses blockchain transactions for migration between DIDs and changes of control, but avoids the need for blockchain transactions for initial account creation and day-to-day updates, by allowing them to be delegated to non-blockchain-based DID methods.

## Status of This Document

This is a draft specification and may be updated, replaced, or obsoleted at any time. It is inappropriate to cite this document as anything other than work in progress.

## 1. Introduction

### 1.1 Motivation

ATProto currently supports two identity standards, did:web and did:plc. These are both potentially problematic for long-term use by users who may be the target of censorship: A did:web ID depends on the continued cooperation of a registrar and the nation state that regulates it, as well as suffering from more mundane issues like forgetting to renew or being priced out by registrar fee increases. A did:plc ID depends on a centralized server, and we have no guarantees about its future behaviour.

Migration between DIDs is not possible, so your did:web identity only lasts as long as your control of your domain does, and your did:plc identity only lasts until the centralized did:plc server starts acting dishonestly.

An alternative would be to use a blockchain-based identity system; There are several mature public blockchains systems that are optimized for censorship resistance. However optimizing for censorship resistance tends to mean deoptimizing in other respects. For example, since public blockchains have limited capacity and do not have anyone in a privileged position who can make judgements about which records are legitimate and which are spam, they typically regulate admission through variable fees. Even if a given system is currently successfully scaling to stay ahead of legitimate demand, there is no guarantee that this will always be true in future.

did:cow is an attempt to get the best of both worlds by adding a blockchain wrapper to did:plc or did:web ID. The wrapper consists of a wrapped DID (did:cow or did:plc), along with a blockchain address with the power to change the ID to which it points. The ID is formed by concatenating its parameters, so until one or the other has been changed, it can be resolved without sending a transaction to the blockchain: You can simply start using the identifier. 

 
### 1.2 Design Goals

1. **Decentralization** - No trusted third-party is responsible for ultimate resolution.
2. **Zero-cost creation** - No blockchain transaction is required to create a did:cow ID.
3. **Method agnosticism** - Any other DID methods supported by ATProto in future can also be wrapped.
4. **Transferability** - The controller used for a did:cow ID can be replaced. If using a smart contract as controller, the controller can be retained but access to the controller changed.
5. **Composability** - The controller can be an arbitrary computer program, allowing sophisticted custom logic and compatibility with multisig and decentralized organization tooling such as [Safe](https://docs.safe.global/home/what-is-safe).
6. **Minimal dependencies** - An Ethereum RPC endpoint is required to resolve, but you should not need additional infrastructure such as an indexer.

## 2. DID Method Name

Method name: `cow` (Consensus Ownership Wrapper)

DID prefix: `did:cow:` (lowercase)

## 3. Method Specific Identifier

Format: `did:cow:<initial_controller_address>:<initial_wrapped_did>`

**Parameters:**
- `initial_controller_address` - Ethereum address, checksum-encoded per [EIP-55](https://eips.ethereum.org/EIPS/eip-55) but with the leading `0x` stripped.
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

Call `resolve(initial_controller_address, initial_wrapped_did)` against the registry contract.

 The did:cow registry contract performs the following steps:

 - If no on-chain record exists, resolve the wrapped DID from the identifier directly.
 - If an on-chain record exists, prepend `did:` to the returned wrapped DID value and resolve that.
 - If the record exists but has been deactivated, return deactivated status.

Resolve the wrapped DID as per that DID system's resolution method.

### 6.3 Update

Send an on-chain transaction from the current controller to either:
- `updateWrappedDID` / `updateWrappedDIDByHash` — set a new wrapped DID omitting the initial "`did:`".
- `updateController` / `updateControllerByHash` — transfer control to a new address

If the did:cow ID has not been registered on-chain yet, `updateWrappedDID` and `updateController` will register it automatically in the same transaction.

### 6.4 Deactivate

Call `deactivate(initial_controller_address, initial_wrapped_did)` from the current controller to permanently deactivate a did:cow ID. If the did:cow ID has not been registered on-chain yet, it will be registered automatically in the same transaction.

After deactivation, `resolve` returns an empty string and the DID cannot be reactivated.

NB: It is permitted to set the controller to `0x0` via `updateController` without deactivating, in which case the DID continues to resolve but can never be updated or deactivated.

## 7. Security Considerations

### 7.1 Controller

The controller address inherits all the security considerations of any other Ethereum address. Addresses can be compromised by phishing, private key leakage etc.

### 7.2 Wrapped DID

The did:cow ID inherits the security risks of the wrapped DID.

However, since users can switch to another wrapped DID they can recover from a compromise of the wrapped DID, and also exit in circumstances where the wrapped DID appears likely to become unreliable in future.

### 7.3 Blockchain Dependencies

**Why Ethereum:**

Ethereum offers high security, an established ecosystem and well-supported tooling for multisig and organizational control. It also operates without needing proof-of-work, which many users dislike for its environmental impact.

Strong social consensus on anti-censorship means we can reasonably confident that the main Ethereum chain will continue accepting updates without censorship for the foreseeable future. We can be even more confident that in the event that the dominant Ethereum chain lost this property, there would be a well-supported fork preserving its history that continued to have it.

**Trade-offs:** 

**Time until finality:** Updates typically take up to 12 seconds to confirm, and longer to finalize.

**Cost**: A system requiring consensus will typically have capacity limits. Systems aiming for censorship resistance cannot exercise discretion about which transactions are worthwhile, so they typically regulate usage by charging fees. Usage is unpredictable, so costs are also unpredictable: Although Ethereum gas prices are currently low, they may increase if usage grows faster than capacity, and may also be subject to sudden spikes. did:cow updates cost 40,000 to 100,000 gas per update depending on DID length and whether the account has already been registered on-chain. This is roughly equivalent to the cost of a transferring a token.

**Why only one chain:**

Some identity standards support multiple chains, for example by putting a Chain ID in the identifier. did:cow supports only a single chain, to avoid the additional complexity, the longer identifiers, and the requirement for resolvers to handle multiple RPC endpoints.

## 8. Privacy Considerations

### 8.1 Controller Address Linkability

`controller_address` is visible as part of the DID and also on-chain once updates are made. Reusing a controller links all DIDs.

### 8.2 On-Chain Metadata

All updates are permanently public with timestamps. This creates an audit trail of updates, previous/new wrapped DIDs, and controller history.

## 9. Reference Implementation

Deployed on Sepolia testnet: [`0x8560798CD78D09143D0194249503ebe25706ed96`](https://sepolia.etherscan.io/address/0x8560798CD78D09143D0194249503ebe25706ed96)

**Contract functions ([`src/CowRegistry.sol`](src/CowRegistry.sol)):**
- `calculateHash(controller, wrappedDID)` — derive the registry key for a did:cow ID
- `resolve(controller, wrappedDID)` — return current controller and wrapped DID without needing to pre-compute the hash
- `initialize(controller, wrappedDID)` — optionally pre-register before first update
- `updateWrappedDID(controller, wrappedDID, newWrappedDID)` — update wrapped DID, registering if needed
- `updateWrappedDIDByHash(cowHash, newWrappedDID)` — update wrapped DID by pre-computed hash
- `updateController(controller, wrappedDID, newController)` — transfer control, registering if needed
- `updateControllerByHash(cowHash, newController)` — transfer control by pre-computed hash
- `deactivate(controller, wrappedDID)` — permanently deactivate, registering if needed
- `deactivateByHash(cowHash)` — permanently deactivate by pre-computed hash

**CLI tool ([`cli/cow.py`](cli/cow.py)):**
- `resolve <did>` — fetch the resolved DID document
- `describe <did>` — show on-chain state (controller, wrapped DID, registration status)
- `initialize <did>` — register on-chain without making any updates (useful to take advantage of low-gas periods)
- `update-wrapped <did> <newWrappedDID>` — update the wrapped DID
- `update-controller <did> <newController>` — transfer control
- `deactivate <did>` — permanently deactivate

**Resolution API ([`web/app.py`](web/app.py)):**

A FastAPI server providing HTTP resolution, hosted at `https://api.cow.watch`. Run with:
```bash
uvicorn app:app --host 127.0.0.1 --port 6666
```
- `GET /<did>` — resolve a did:cow DID and return the modified DID document (mirrors the [plc.directory](https://plc.directory) API shape)
- `GET /<did>/describe` — return on-chain state without fetching the wrapped DID document
- `GET /api/config` — return contract address and chain ID (used by the web UI)

A systemd unit file is provided at [`web/cow-api.service`](web/cow-api.service).

**Web UI ([`web/static/index.html`](web/static/index.html)):**

A static single-page app hosted at `https://cow.watch`.
- **Resolve** — enter a did:cow DID to fetch and display the DID document, with the current controller and wrapped DID shown as editable fields
- **Create** — construct a did:cow identifier from a controller address and wrapped DID, with an animated reveal
- **Edit** — update the controller or wrapped DID via a MetaMask transaction (visible after resolving; requires wallet connection)
- Deep-linking: `https://cow.watch/#!/did:cow:...` auto-resolves on load

## 10. Example DID Document

This example shows a did:cow ID wrapping a did:plc identity. The resolved document is the underlying did:plc document with three modifications: the `id` is replaced with the did:cow identifier, and a `did:cow` block is added carrying the Ethereum controller address (as a did:pkh DID) and the wrapped DID for client validation.

Given:
```
did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:plc:pyzlzqt6b2nyrha7smfry6rv
```

Wrapping:
```
did:plc:pyzlzqt6b2nyrha7smfry6rv
```

Resolved DID Document:
```json
{
  "@context": [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/multikey/v1"
  ],
  "id": "did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:plc:pyzlzqt6b2nyrha7smfry6rv",
  "did:cow": {
    "controller": "did:pkh:eip155:1:0x8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be",
    "wrappedDid": "did:plc:pyzlzqt6b2nyrha7smfry6rv"
  },
  "alsoKnownAs": [
    "at://user.bsky.social"
  ],
  "verificationMethod": [
    {
      "id": "did:plc:pyzlzqt6b2nyrha7smfry6rv#atproto",
      "type": "Multikey",
      "controller": "did:plc:pyzlzqt6b2nyrha7smfry6rv",
      "publicKeyMultibase": "zQ3shRQWmWxEtxRa317rpYnVo7nWxYAsDS4mBwdDLgLfkkDtR"
    }
  ],
  "service": [
    {
      "id": "#atproto_pds",
      "type": "AtprotoPersonalDataServer",
      "serviceEndpoint": "https://bsky.social"
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
