// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CowRegistry {

    struct Cow {
        address controller;
        string wrappedDID;
    }

    string constant DEACTIVATED = "did::";

    mapping(bytes32 => Cow) public cows;

    event CowInitialized(bytes32 indexed cowHash, address controller, string wrappedDID);
    event CowDeactivated(bytes32 indexed cowHash);
    event ControllerUpdated(bytes32 indexed cowHash, address controller);
    event WrappedDIDUpdated(bytes32 indexed cowHash, string wrappedDID);

    function _isDeactivated(bytes32 cowHash) internal view returns (bool) {
        return keccak256(bytes(cows[cowHash].wrappedDID)) == keccak256(bytes(DEACTIVATED));
    }

    function updateWrappedDIDByHash(bytes32 cowHash, string memory wrappedDID) public {
        require(!_isDeactivated(cowHash));
        require(msg.sender == cows[cowHash].controller);
        require(keccak256(bytes(wrappedDID)) != keccak256(bytes(DEACTIVATED)), "Use deactivate() to deactivate");

        cows[cowHash].wrappedDID = wrappedDID;
        emit WrappedDIDUpdated(cowHash, wrappedDID);
    }

    function updateControllerByHash(bytes32 cowHash, address controller) public {
        require(!_isDeactivated(cowHash));
        require(msg.sender == cows[cowHash].controller);

        cows[cowHash].controller = controller;
        emit ControllerUpdated(cowHash, controller);
    }

    function calculateCowHash(address controller, string memory wrappedDID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(controller, wrappedDID));
    }

    function _ensureCowInitialized(address controller, string memory wrappedDID) internal returns (bytes32 cowHash) {
        cowHash = calculateCowHash(controller, wrappedDID);
        if (bytes(cows[cowHash].wrappedDID).length == 0) {
            cows[cowHash] = Cow(controller, wrappedDID);
            emit CowInitialized(cowHash, controller, wrappedDID);
        }
        return cowHash;
    }

    // You don't particularly need to call this, you can leave it until you make an update
    function initializeCow(address controller, string memory wrappedDID) external {
        _ensureCowInitialized(controller, wrappedDID);
    }

    function updateWrappedDID(address controller, string memory wrappedDID, string memory newWrappedDID) public {
        bytes32 cowHash = _ensureCowInitialized(controller, wrappedDID);
        updateWrappedDIDByHash(cowHash, newWrappedDID);
    }

    function updateController(address controller, string memory wrappedDID, address newController) public {
        bytes32 cowHash = _ensureCowInitialized(controller, wrappedDID);
        updateControllerByHash(cowHash, newController);
    }

    function deactivate(bytes32 cowHash) external {
        require(!_isDeactivated(cowHash));
        require(msg.sender == cows[cowHash].controller);

        cows[cowHash].wrappedDID = DEACTIVATED;
        cows[cowHash].controller = address(0);

        emit CowDeactivated(cowHash);
    }
}
