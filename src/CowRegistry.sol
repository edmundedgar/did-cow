// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title CowRegistry
/// @notice On-chain registry for the did:cow (Consensus Ownership Wrapper) DID method.
/// @dev A did:cow DID is identified by its initial controller address and initial wrapped DID
///      (stored without the leading "did:" prefix, e.g. "plc:abc123" or "web:example.com").
///      Creation is off-chain and free. This contract only needs to be called when migrating
///      to a new wrapped DID, transferring control, or deactivating.
contract CowRegistry {

    /// @notice On-chain state for a single did:cow identifier.
    /// @dev The cowHash key is derived from the *initial* controller and wrapped DID,
    ///      so these fields reflect the *current* state after any updates.
    ///      controller and deactivated are packed into a single storage slot.
    struct Cow {
        address controller;
        bool deactivated;
        bool initialized;
        string wrappedDID;
    }

    error NotInitialized();
    error NotController();
    error AlreadyDeactivated();
    error EmptyWrappedDID();

    /// @notice Mapping from cow hash to current on-chain state.
    /// @dev Returns zero values if the cow has never been registered on-chain.
    mapping(bytes32 => Cow) public cows;

    /// @notice Emitted when a cow is registered on-chain for the first time.
    event CowInitialized(bytes32 indexed cowHash, address controller, string wrappedDID);

    /// @notice Emitted when a cow is permanently deactivated.
    event CowDeactivated(bytes32 indexed cowHash);

    /// @notice Emitted when a cow's controller address is updated.
    event ControllerUpdated(bytes32 indexed cowHash, address controller);

    /// @notice Emitted when a cow's wrapped DID is updated.
    event WrappedDIDUpdated(bytes32 indexed cowHash, string wrappedDID);

    /// @notice Update the wrapped DID for an already-registered cow.
    /// @dev Caller must be the current controller. Use updateWrappedDID if the cow
    ///      may not yet be registered on-chain.
    /// @param _cowHash The cow's registry key, as returned by calculateCowHash.
    /// @param _wrappedDID The new wrapped DID, without the leading "did:" prefix.
    function updateWrappedDIDByHash(bytes32 _cowHash, string memory _wrappedDID) public {
        Cow storage cow = cows[_cowHash];
        if (!cow.initialized) revert NotInitialized();
        if (cow.deactivated) revert AlreadyDeactivated();
        if (msg.sender != cow.controller) revert NotController();
        if (bytes(_wrappedDID).length == 0) revert EmptyWrappedDID();

        cow.wrappedDID = _wrappedDID;
        emit WrappedDIDUpdated(_cowHash, _wrappedDID);
    }

    /// @notice Transfer control of an already-registered cow to a new address.
    /// @dev Caller must be the current controller. Use updateController if the cow
    ///      may not yet be registered on-chain.
    ///      Setting _controller to address(0) makes the cow permanently uncontrollable
    ///      without deactivating it — it will continue to resolve but can never be updated.
    /// @param _cowHash The cow's registry key, as returned by calculateCowHash.
    /// @param _controller The new controller address.
    function updateControllerByHash(bytes32 _cowHash, address _controller) public {
        Cow storage cow = cows[_cowHash];
        if (!cow.initialized) revert NotInitialized();
        if (cow.deactivated) revert AlreadyDeactivated();
        if (msg.sender != cow.controller) revert NotController();

        cow.controller = _controller;
        emit ControllerUpdated(_cowHash, _controller);
    }

    /// @notice Permanently deactivate an already-registered cow.
    /// @dev Caller must be the current controller. Deactivation is irreversible.
    ///      Use deactivate if the cow may not yet be registered on-chain.
    /// @param _cowHash The cow's registry key, as returned by calculateCowHash.
    function deactivateByHash(bytes32 _cowHash) public {
        Cow storage cow = cows[_cowHash];
        if (!cow.initialized) revert NotInitialized();
        if (cow.deactivated) revert AlreadyDeactivated();
        if (msg.sender != cow.controller) revert NotController();

        cow.deactivated = true;
        cow.controller = address(0);
        cow.wrappedDID = "";

        emit CowDeactivated(_cowHash);
    }

    /// @notice Derive the registry key for a did:cow identifier.
    /// @param _controller The initial controller address.
    /// @param _wrappedDID The initial wrapped DID, without the leading "did:" prefix.
    /// @return The keccak256 hash used as the key in the cows mapping.
    function calculateCowHash(address _controller, string memory _wrappedDID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_controller, _wrappedDID));
    }

    /// @dev Register a cow on-chain if not already present, then return its hash.
    function _ensureCowInitialized(address _controller, string memory _wrappedDID) internal returns (bytes32 cowHash) {
        cowHash = calculateCowHash(_controller, _wrappedDID);
        Cow storage cow = cows[cowHash];
        if (cow.deactivated) revert AlreadyDeactivated();
        if (!cow.initialized) {
            cow.initialized = true;
            cow.controller = _controller;
            cow.wrappedDID = _wrappedDID;
            emit CowInitialized(cowHash, _controller, _wrappedDID);
        }
        return cowHash;
    }

    /// @notice Resolve a did:cow identifier to its current wrapped DID and controller.
    /// @dev Returns the initial values if the cow has never been registered on-chain.
    /// @param _controller The initial controller address from the did:cow identifier.
    /// @param _wrappedDID The initial wrapped DID from the did:cow identifier, without "did:".
    /// @return wrappedDID The current full wrapped DID (with "did:" prepended), or empty string if deactivated.
    /// @return controller The current controller address.
    function resolveCow(address _controller, string memory _wrappedDID) external view returns (string memory wrappedDID, address controller) {
        bytes32 cowHash = calculateCowHash(_controller, _wrappedDID);
        Cow storage cow = cows[cowHash];
        if (cow.deactivated) {
            return ("", address(0));
        }
        if (!cow.initialized) {
            return (string.concat("did:", _wrappedDID), _controller);
        }
        return (string.concat("did:", cow.wrappedDID), cow.controller);
    }

    /// @notice Optionally pre-register a cow on-chain before its first update.
    /// @dev This is never strictly necessary — updateWrappedDID, updateController, and
    ///      deactivate all register the cow automatically if needed.
    /// @param _controller The initial controller address.
    /// @param _wrappedDID The initial wrapped DID, without the leading "did:" prefix.
    function initializeCow(address _controller, string memory _wrappedDID) external {
        _ensureCowInitialized(_controller, _wrappedDID);
    }

    /// @notice Update the wrapped DID, registering the cow on-chain if not already present.
    /// @param _controller The initial controller address from the did:cow identifier.
    /// @param _wrappedDID The initial wrapped DID from the did:cow identifier, without "did:".
    /// @param _newWrappedDID The new wrapped DID, without the leading "did:" prefix.
    function updateWrappedDID(address _controller, string memory _wrappedDID, string memory _newWrappedDID) external {
        bytes32 cowHash = _ensureCowInitialized(_controller, _wrappedDID);
        updateWrappedDIDByHash(cowHash, _newWrappedDID);
    }

    /// @notice Transfer control to a new address, registering the cow on-chain if not already present.
    /// @param _controller The initial controller address from the did:cow identifier.
    /// @param _wrappedDID The initial wrapped DID from the did:cow identifier, without "did:".
    /// @param _newController The new controller address.
    function updateController(address _controller, string memory _wrappedDID, address _newController) external {
        bytes32 cowHash = _ensureCowInitialized(_controller, _wrappedDID);
        updateControllerByHash(cowHash, _newController);
    }

    /// @notice Permanently deactivate a cow, registering it on-chain if not already present.
    /// @dev Deactivation is irreversible.
    /// @param _controller The initial controller address from the did:cow identifier.
    /// @param _wrappedDID The initial wrapped DID from the did:cow identifier, without "did:".
    function deactivate(address _controller, string memory _wrappedDID) external {
        bytes32 cowHash = _ensureCowInitialized(_controller, _wrappedDID);
        deactivateByHash(cowHash);
    }
}
