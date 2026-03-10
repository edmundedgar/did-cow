// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CowRegistry {

    struct Cow {
        address controller;
        bytes12 prefix; // set to "did::" to deactivate
        string wrappedDID;
    }

    mapping(bytes32 => Cow) public cows;

    event CowInitialized(bytes32 indexed cowHash, address controller, bytes12 prefix, string wrappedDID);
    event CowDeactivated(bytes32 indexed cowHash);
    event ControllerUpdated(bytes32 indexed cowHash, address controller);
    event WrappedDIDUpdated(bytes32 indexed cowHash, bytes12 prefix, string wrappedDID);

    function updateWrappedDIDByHash(
        bytes32 cowHash,
        bytes12 prefix,
        string memory wrappedDID
    ) public {
        require(cows[cowHash].prefix != bytes12("did::"));
        require(msg.sender == cows[cowHash].controller);

        require(prefix != bytes12("did::"), "Use deactivate() to deactivate");

        cows[cowHash].prefix = prefix;
        cows[cowHash].wrappedDID = wrappedDID;
        emit WrappedDIDUpdated(cowHash, prefix, wrappedDID);
    }

    function updateControllerByHash(
        bytes32 cowHash,
        address controller
    ) public {
        require(cows[cowHash].prefix != bytes12("did::"));
        require(msg.sender == cows[cowHash].controller);

        cows[cowHash].controller = controller;
        emit ControllerUpdated(cowHash, controller);
    }

    function calculateCowHash(address controller, bytes12 prefix, string memory wrappedDID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(controller, prefix, wrappedDID));
    }

    // Return a cow hash for the settings, storing the cow if it was not already there
    function _ensureCowInitialized(address controller, bytes12 prefix, string memory wrappedDID) internal returns (bytes32 cowHash) {
        cowHash = calculateCowHash(controller, prefix, wrappedDID);
        if (cows[cowHash].prefix == bytes12(0)) { // unregistered
            cows[cowHash] = Cow(
                controller,
                prefix,
                wrappedDID
            );
            emit CowInitialized(cowHash, controller, prefix, wrappedDID);
        }
        return cowHash;
    }

    // You don't particularly need to call this, you can leave it until you make an update
    function initializeCow(address controller, bytes12 prefix, string memory wrappedDID) external {
        _ensureCowInitialized(controller, prefix, wrappedDID);
    }

    function updateWrappedDID(address controller, bytes12 prefix, string memory wrappedDID, bytes12 newPrefix, string memory newWrappedDID) public {
        bytes32 cowHash = _ensureCowInitialized(controller, prefix, wrappedDID);
        updateWrappedDIDByHash(cowHash, newPrefix, newWrappedDID);
    }

    function updateController(address controller, bytes12 prefix, string memory wrappedDID, address newController) public {
        bytes32 cowHash = _ensureCowInitialized(controller, prefix, wrappedDID);
        updateControllerByHash(cowHash, newController);
    }

    function deactivate(bytes32 cowHash) external {
        require(cows[cowHash].prefix != bytes12("did::"));
        require(msg.sender == cows[cowHash].controller);

        cows[cowHash].prefix = bytes12("did::");
        cows[cowHash].controller = address(0);

        emit CowDeactivated(cowHash);
    }

}
