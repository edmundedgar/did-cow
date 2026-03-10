contract CowRegistry {

    struct Cow {
        address controller;
        bytes12 prefix; // set to "did::" to deactivate
        string wrappedDID;
    }
    
    mapping(bytes32 => Cow) public cows;
    
    event CowInitialized(bytes32 indexed cowHash, address controller, bytes8 prefix, string wrappedDID);
    event CowDeactivated(bytes32 indexed cowHash);
    event ControllerUpdated(bytes32 indexed cowHash, address controller);
    event WrappedDIDUpdated(bytes32 indexed cowHash, bytes12 prefix, bytes wrappedDID);

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

    function calculateCowHash(address controller, bytes12 prefix, string wrappedDID) public pure returns (bytes32 cowHash) {
        return keccak256(abi.encodePacked(controller, prefix, wrappedDID));
    }

    // Return a Cow struct for the settings, storing it if it was not already there
    function _ensureCowInitialized(address controller, bytes12 prefix, string wrappedDID) internal returns (bytes32 cowHash) {
        bytes32 cowHash = calculateCowHash(controller, prefix, wrappedDID);
        if (cows[cowHash].prefix == bytes12(0)) { // unregistered
            cows[cowHash] = Cow(
                controller,
                prefix,
                wrappedDID
            );
            emit CowInitialized(cowHash, controller, bytes12, prefix, wrappedDID);
        }
        return cowHash;
    }

    // You don't particularly need to call this, you can leave it until you make an update
    function initializeCow(address controller, bytes12 prefix, string wrappedDID) external {
        _ensureCowInitialized(address, prefix, wrappedDID);
    }

    function updateWrappedDID(address controller, bytes12 prefix, string wrappedDID, address newController) {
        bytes cowHash = _initializedCow(controller, prefix, wrappedDID);
        updateWrappedDIDByHash(cowHash, prefix, wrappedDID);
    }
    
    function updateController(address controller, bytes12 prefix, string wrappedDID, address newController) {
        bytes cowHash = _initializedCow(controller, prefix, wrappedDID);
        updateControllerByHash(cowHash, newController);
    }
    
    function deactivate(bytes32 cowHash) external {
        require(prefix != bytes12("did::");
        require(cows[cowHash].prefix != bytes12("did::"));
        
        require(msg.sender == cows[cowHash].controller);
        cows[cowHash].prefix = bytes12("did::");
        cows[cowHash].controller = address(0);

        emit DIDDeactivated(cowHash);
    }
    
}
