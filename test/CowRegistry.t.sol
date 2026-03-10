// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CowRegistry.sol";

contract CowRegistryUpdateTest is Test {
    CowRegistry registry;

    address controller1 = address(0x1111);
    address controller2 = address(0x2222);

    // Two did:plc addresses
    bytes12 plcPrefix = bytes12("did:plc:");
    string plcDID1    = "7qqsrnkn4moc2jgd"; // did:plc:7qqsrnkn4moc2jgd
    string plcDID2    = "abcdefghijklmnop"; // did:plc:abcdefghijklmnop

    // did:web addresses of varying lengths
    bytes12 webPrefix     = bytes12("did:web:");
    string webDIDShort    = "a.io";            // did:web:a.io
    string webDIDMedium   = "example.com";     // did:web:example.com
    string webDIDLong     = "subdomain.very-long-hostname.example.co.uk"; // did:web:subdomain...
    string webDIDVeryLong = "deep.nested.subdomain.with-a-quite-long-hostname.enterprise.example.com"; // did:web:...

    function setUp() public {
        registry = new CowRegistry();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _hashFor(address ctrl, bytes12 pfx, string memory did) internal view returns (bytes32) {
        return registry.calculateCowHash(ctrl, pfx, did);
    }

    function _init(address ctrl, bytes12 pfx, string memory did) internal returns (bytes32) {
        registry.initializeCow(ctrl, pfx, did);
        return _hashFor(ctrl, pfx, did);
    }

    // -------------------------------------------------------------------------
    // updateWrappedDID — did:plc
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_plc1_to_plc2() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, plcPrefix, plcDID2);
        uint256 gasUsed = gasBefore - gasleft();

        (, bytes12 pfx, string memory did) = registry.cows(cowHash);
        assertEq(pfx, plcPrefix);
        assertEq(did, plcDID2);
        emit log_named_uint("gas updateWrappedDID plc1->plc2", gasUsed);
    }

    function test_updateWrappedDID_plc2_to_plc1() public {
        bytes32 cowHash = _init(controller2, plcPrefix, plcDID2);

        vm.prank(controller2);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, plcPrefix, plcDID1);
        uint256 gasUsed = gasBefore - gasleft();

        (, , string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID1);
        emit log_named_uint("gas updateWrappedDID plc2->plc1", gasUsed);
    }

    // -------------------------------------------------------------------------
    // updateWrappedDID — did:web varying lengths
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_web_short() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, webPrefix, webDIDShort);
        uint256 gasUsed = gasBefore - gasleft();

        (, bytes12 pfx, string memory did) = registry.cows(cowHash);
        assertEq(pfx, webPrefix);
        assertEq(did, webDIDShort);
        emit log_named_uint("gas updateWrappedDID web short (4 chars)", gasUsed);
    }

    function test_updateWrappedDID_web_medium() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, webPrefix, webDIDMedium);
        uint256 gasUsed = gasBefore - gasleft();

        (, , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDMedium);
        emit log_named_uint("gas updateWrappedDID web medium (11 chars)", gasUsed);
    }

    function test_updateWrappedDID_web_long() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, webPrefix, webDIDLong);
        uint256 gasUsed = gasBefore - gasleft();

        (, , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDLong);
        emit log_named_uint("gas updateWrappedDID web long (42 chars)", gasUsed);
    }

    function test_updateWrappedDID_web_verylong() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateWrappedDIDByHash(cowHash, webPrefix, webDIDVeryLong);
        uint256 gasUsed = gasBefore - gasleft();

        (, , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDVeryLong);
        emit log_named_uint("gas updateWrappedDID web very long (71 chars)", gasUsed);
    }

    // -------------------------------------------------------------------------
    // updateController — did:plc
    // -------------------------------------------------------------------------

    function test_updateController_plc1() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller2);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
        emit log_named_uint("gas updateController plc1 ctrl1->ctrl2", gasUsed);
    }

    function test_updateController_plc2() public {
        bytes32 cowHash = _init(controller2, plcPrefix, plcDID2);

        vm.prank(controller2);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller1);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller1);
        emit log_named_uint("gas updateController plc2 ctrl2->ctrl1", gasUsed);
    }

    // -------------------------------------------------------------------------
    // updateController — did:web varying lengths
    // -------------------------------------------------------------------------

    function test_updateController_web_short() public {
        bytes32 cowHash = _init(controller1, webPrefix, webDIDShort);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller2);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
        emit log_named_uint("gas updateController web short (4 chars)", gasUsed);
    }

    function test_updateController_web_medium() public {
        bytes32 cowHash = _init(controller1, webPrefix, webDIDMedium);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller2);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
        emit log_named_uint("gas updateController web medium (11 chars)", gasUsed);
    }

    function test_updateController_web_long() public {
        bytes32 cowHash = _init(controller1, webPrefix, webDIDLong);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller2);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
        emit log_named_uint("gas updateController web long (42 chars)", gasUsed);
    }

    function test_updateController_web_verylong() public {
        bytes32 cowHash = _init(controller1, webPrefix, webDIDVeryLong);

        vm.prank(controller1);
        uint256 gasBefore = gasleft();
        registry.updateControllerByHash(cowHash, controller2);
        uint256 gasUsed = gasBefore - gasleft();

        (address ctrl, , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
        emit log_named_uint("gas updateController web very long (71 chars)", gasUsed);
    }

    // -------------------------------------------------------------------------
    // Auth checks
    // -------------------------------------------------------------------------

    function test_updateWrappedDID_rejectsNonController() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller2);
        vm.expectRevert();
        registry.updateWrappedDIDByHash(cowHash, plcPrefix, plcDID2);
    }

    function test_updateController_rejectsNonController() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller2);
        vm.expectRevert();
        registry.updateControllerByHash(cowHash, controller2);
    }

    function test_updateWrappedDID_rejectsAfterDeactivation() public {
        bytes32 cowHash = _init(controller1, plcPrefix, plcDID1);

        vm.prank(controller1);
        registry.deactivate(cowHash);

        vm.prank(address(0));
        vm.expectRevert();
        registry.updateWrappedDIDByHash(cowHash, plcPrefix, plcDID2);
    }
}
