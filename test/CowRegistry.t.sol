// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/CowRegistry.sol";

contract CowRegistryUpdateTest is Test {
    CowRegistry registry;

    address controller1 = address(0x1111);
    address controller2 = address(0x2222);

    // Two did:plc addresses (did: prefix implied; 4 char prefix + 24 char base32 = 28 chars total)
    string plcDID1 = "plc:7qqsrnkn4moc2jgdxvh6aa3t";
    string plcDID2 = "plc:abcdefghijklmnopqrstuvwx";

    // did:web addresses of varying lengths (did: prefix implied)
    string webDIDShort    = "web:a.io";
    string webDIDMedium   = "web:example.com";
    string webDIDLong     = "web:subdomain.very-long-hostname.example.co.uk";
    string webDIDVeryLong = "web:deep.nested.subdomain.with-a-quite-long-hostname.enterprise.example.com";

    function setUp() public {
        registry = new CowRegistry();
    }

    function _init(address ctrl, string memory did) internal returns (bytes32) {
        registry.initializeCow(ctrl, did);
        return registry.calculateCowHash(ctrl, did);
    }

    // -------------------------------------------------------------------------
    // updateWrappedDID — did:plc
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_plc1_to_plc2() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, plcDID2);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID2);
    }

    function test_updateWrappedDID_plc2_to_plc1() public {
        bytes32 cowHash = _init(controller2, plcDID2);

        vm.prank(controller2);
        registry.updateWrappedDIDByHash(cowHash, plcDID1);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID1);
    }

    // -------------------------------------------------------------------------
    // updateWrappedDID — did:web varying lengths
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_web_short() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDShort);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDShort);
    }

    function test_updateWrappedDID_web_medium() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDMedium);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDMedium);
    }

    function test_updateWrappedDID_web_long() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDLong);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDLong);
    }

    function test_updateWrappedDID_web_verylong() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDVeryLong);

        (, string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDVeryLong);
    }

    // -------------------------------------------------------------------------
    // updateController — did:plc
    // -------------------------------------------------------------------------

    function test_updateController_plc1() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_updateController_plc2() public {
        bytes32 cowHash = _init(controller2, plcDID2);

        vm.prank(controller2);
        registry.updateControllerByHash(cowHash, controller1);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller1);
    }

    // -------------------------------------------------------------------------
    // updateController — did:web varying lengths
    // -------------------------------------------------------------------------

    function test_updateController_web_short() public {
        bytes32 cowHash = _init(controller1, webDIDShort);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_updateController_web_medium() public {
        bytes32 cowHash = _init(controller1, webDIDMedium);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_updateController_web_long() public {
        bytes32 cowHash = _init(controller1, webDIDLong);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_updateController_web_verylong() public {
        bytes32 cowHash = _init(controller1, webDIDVeryLong);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    // -------------------------------------------------------------------------
    // Auth checks
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_rejectsNonController() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller2);
        vm.expectRevert();
        registry.updateWrappedDIDByHash(cowHash, plcDID2);
    }

    function test_updateController_rejectsNonController() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller2);
        vm.expectRevert();
        registry.updateControllerByHash(cowHash, controller2);
    }

    function test_updateWrappedDID_rejectsAfterDeactivation() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.deactivate(cowHash);

        vm.prank(controller1);
        vm.expectRevert();
        registry.updateWrappedDIDByHash(cowHash, plcDID2);
    }
}
