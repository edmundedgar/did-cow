// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

    function updateWrappedDIDByHash(bytes32 _cowHash, string memory _wrappedDID) public {
        require(msg.sender == cows[_cowHash].controller);
        require(bytes(_wrappedDID).length > 5, "Use deactivate() to deactivate");

        cows[_cowHash].wrappedDID = _wrappedDID;
        emit WrappedDIDUpdated(_cowHash, _wrappedDID);
    }

    function updateControllerByHash(bytes32 _cowHash, address _controller) public {
        require(msg.sender == cows[_cowHash].controller);

        cows[_cowHash].controller = _controller;
        emit ControllerUpdated(_cowHash, _controller);
    }

    function calculateCowHash(address _controller, string memory _wrappedDID) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_controller, _wrappedDID));
    }

    function _ensureCowInitialized(address _controller, string memory _wrappedDID) internal returns (bytes32 cowHash) {
        cowHash = calculateCowHash(_controller, _wrappedDID);
        if (bytes(cows[cowHash].wrappedDID).length == 0) {
            cows[cowHash] = Cow(_controller, _wrappedDID);
            emit CowInitialized(cowHash, _controller, _wrappedDID);
        }
        return cowHash;
    }

    // You don't particularly need to call this, you can leave it until you make an update
    function initializeCow(address _controller, string memory _wrappedDID) external {
        _ensureCowInitialized(_controller, _wrappedDID);
    }

    function updateWrappedDID(address _controller, string memory _wrappedDID, string memory _newWrappedDID) external {
        bytes32 cowHash = _ensureCowInitialized(_controller, _wrappedDID);
        updateWrappedDIDByHash(cowHash, _newWrappedDID);
    }

    function updateController(address _controller, string memory _wrappedDID, address _newController) external {
        bytes32 cowHash = _ensureCowInitialized(_controller, _wrappedDID);
        updateControllerByHash(cowHash, _newController);
    }

    function deactivate(bytes32 _cowHash) external {
        require(msg.sender == cows[_cowHash].controller);

        cows[_cowHash].wrappedDID = DEACTIVATED;
        cows[_cowHash].controller = address(0);

        emit CowDeactivated(_cowHash);
    }
}
