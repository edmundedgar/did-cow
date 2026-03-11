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

    // =========================================================================
    // updateWrappedDID — pre-registered (initializeCow already called)
    // =========================================================================

    function test_preregistered_updateWrappedDID_plc1_to_plc2() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, plcDID2);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID2);
    }

    function test_preregistered_updateWrappedDID_plc2_to_plc1() public {
        bytes32 cowHash = _init(controller2, plcDID2);

        vm.prank(controller2);
        registry.updateWrappedDIDByHash(cowHash, plcDID1);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID1);
    }

    function test_preregistered_updateWrappedDID_web_short() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDShort);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDShort);
    }

    function test_preregistered_updateWrappedDID_web_medium() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDMedium);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDMedium);
    }

    function test_preregistered_updateWrappedDID_web_long() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDLong);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDLong);
    }

    function test_preregistered_updateWrappedDID_web_verylong() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateWrappedDIDByHash(cowHash, webDIDVeryLong);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDVeryLong);
    }

    // =========================================================================
    // updateController — pre-registered
    // =========================================================================

    function test_preregistered_updateController_plc1() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_preregistered_updateController_plc2() public {
        bytes32 cowHash = _init(controller2, plcDID2);

        vm.prank(controller2);
        registry.updateControllerByHash(cowHash, controller1);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller1);
    }

    function test_preregistered_updateController_web_short() public {
        bytes32 cowHash = _init(controller1, webDIDShort);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_preregistered_updateController_web_medium() public {
        bytes32 cowHash = _init(controller1, webDIDMedium);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_preregistered_updateController_web_long() public {
        bytes32 cowHash = _init(controller1, webDIDLong);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_preregistered_updateController_web_verylong() public {
        bytes32 cowHash = _init(controller1, webDIDVeryLong);

        vm.prank(controller1);
        registry.updateControllerByHash(cowHash, controller2);

        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    // =========================================================================
    // updateWrappedDID — on first update (registration + update in one tx)
    // =========================================================================

    function test_on_first_update_updateWrappedDID_plc1_to_plc2() public {
        vm.prank(controller1);
        registry.updateWrappedDID(controller1, plcDID1, plcDID2);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID2);
    }

    function test_on_first_update_updateWrappedDID_plc2_to_plc1() public {
        vm.prank(controller2);
        registry.updateWrappedDID(controller2, plcDID2, plcDID1);

        bytes32 cowHash = registry.calculateCowHash(controller2, plcDID2);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, plcDID1);
    }

    function test_on_first_update_updateWrappedDID_web_short() public {
        vm.prank(controller1);
        registry.updateWrappedDID(controller1, plcDID1, webDIDShort);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDShort);
    }

    function test_on_first_update_updateWrappedDID_web_medium() public {
        vm.prank(controller1);
        registry.updateWrappedDID(controller1, plcDID1, webDIDMedium);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDMedium);
    }

    function test_on_first_update_updateWrappedDID_web_long() public {
        vm.prank(controller1);
        registry.updateWrappedDID(controller1, plcDID1, webDIDLong);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDLong);
    }

    function test_on_first_update_updateWrappedDID_web_verylong() public {
        vm.prank(controller1);
        registry.updateWrappedDID(controller1, plcDID1, webDIDVeryLong);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, webDIDVeryLong);
    }

    // =========================================================================
    // updateController — on first update
    // =========================================================================

    function test_on_first_update_updateController_plc1() public {
        vm.prank(controller1);
        registry.updateController(controller1, plcDID1, controller2);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_on_first_update_updateController_plc2() public {
        vm.prank(controller2);
        registry.updateController(controller2, plcDID2, controller1);

        bytes32 cowHash = registry.calculateCowHash(controller2, plcDID2);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller1);
    }

    function test_on_first_update_updateController_web_short() public {
        vm.prank(controller1);
        registry.updateController(controller1, webDIDShort, controller2);

        bytes32 cowHash = registry.calculateCowHash(controller1, webDIDShort);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_on_first_update_updateController_web_medium() public {
        vm.prank(controller1);
        registry.updateController(controller1, webDIDMedium, controller2);

        bytes32 cowHash = registry.calculateCowHash(controller1, webDIDMedium);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_on_first_update_updateController_web_long() public {
        vm.prank(controller1);
        registry.updateController(controller1, webDIDLong, controller2);

        bytes32 cowHash = registry.calculateCowHash(controller1, webDIDLong);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    function test_on_first_update_updateController_web_verylong() public {
        vm.prank(controller1);
        registry.updateController(controller1, webDIDVeryLong, controller2);

        bytes32 cowHash = registry.calculateCowHash(controller1, webDIDVeryLong);
        (address ctrl, , , ) = registry.cows(cowHash);
        assertEq(ctrl, controller2);
    }

    // =========================================================================
    // Auth checks
    // =========================================================================

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
        _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.deactivate(controller1, plcDID1);

        bytes32 cowHash = registry.calculateCowHash(controller1, plcDID1);
        vm.prank(controller1);
        vm.expectRevert();
        registry.updateWrappedDIDByHash(cowHash, plcDID2);
    }

    function test_updateController_rejectsAfterDeactivation() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.deactivateByHash(cowHash);

        vm.prank(controller1);
        vm.expectRevert();
        registry.updateControllerByHash(cowHash, controller2);
    }

    function test_deactivate_rejectsAlreadyDeactivated() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.deactivateByHash(cowHash);

        vm.prank(controller1);
        vm.expectRevert();
        registry.deactivateByHash(cowHash);
    }

    function test_deactivate_clearsWrappedDID() public {
        bytes32 cowHash = _init(controller1, plcDID1);

        vm.prank(controller1);
        registry.deactivateByHash(cowHash);

        (, , , string memory did) = registry.cows(cowHash);
        assertEq(did, "");
    }
}
