// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MilestoneHook} from "../src/MilestoneHook.sol";
import {MockAgenticCommerce} from "./mocks/MockAgenticCommerce.sol";

contract MilestoneHookTest is Test {
    MockAgenticCommerce internal commerce;
    MilestoneHook internal hook;

    address internal client = makeAddr("client");
    address internal provider = makeAddr("provider");
    address internal evaluator = makeAddr("evaluator");

    uint256 internal jobId;

    function setUp() public {
        commerce = new MockAgenticCommerce(address(0));
        hook = new MilestoneHook(address(commerce));
        vm.prank(client);
        jobId = commerce.createJob(provider, evaluator, block.timestamp + 1 days, "phased build", address(hook));
    }

    function _configureThreeMilestones() internal {
        bytes32[] memory names = new bytes32[](3);
        names[0] = "design";
        names[1] = "implement";
        names[2] = "test";
        uint256[] memory weights = new uint256[](3);
        weights[0] = 3000;
        weights[1] = 5000;
        weights[2] = 2000;
        vm.prank(client);
        hook.configure(jobId, names, weights);
    }

    function test_configure_storesAllMilestones() public {
        _configureThreeMilestones();
        assertTrue(hook.initialized(jobId));
        MilestoneHook.Milestone[] memory ms = hook.getMilestones(jobId);
        assertEq(ms.length, 3);
        assertEq(ms[0].name, bytes32("design"));
        assertEq(ms[1].weight, 5000);
    }

    function test_configure_revertsOnWeightSumNot10000() public {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "a";
        names[1] = "b";
        uint256[] memory weights = new uint256[](2);
        weights[0] = 3000;
        weights[1] = 5000; // sum 8000 not 10000
        vm.prank(client);
        vm.expectRevert();
        hook.configure(jobId, names, weights);
    }

    function test_configure_revertsOnLengthMismatch() public {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "a";
        names[1] = "b";
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        vm.prank(client);
        vm.expectRevert();
        hook.configure(jobId, names, weights);
    }

    function test_configure_revertsIfNotClient() public {
        bytes32[] memory names = new bytes32[](1);
        names[0] = "single";
        uint256[] memory weights = new uint256[](1);
        weights[0] = 10000;
        vm.prank(provider);
        vm.expectRevert();
        hook.configure(jobId, names, weights);
    }

    function test_approveMilestone_onlyEvaluator() public {
        _configureThreeMilestones();
        vm.prank(client);
        vm.expectRevert();
        hook.approveMilestone(jobId, 0);
    }

    function test_approveMilestone_recordsApproval() public {
        _configureThreeMilestones();
        vm.prank(evaluator);
        hook.approveMilestone(jobId, 0);
        assertEq(hook.approvedCount(jobId), 1);
        assertEq(hook.approvedWeight(jobId), 3000);
        MilestoneHook.Milestone[] memory ms = hook.getMilestones(jobId);
        assertTrue(ms[0].approved);
    }

    function test_approveMilestone_doubleApproveReverts() public {
        _configureThreeMilestones();
        vm.startPrank(evaluator);
        hook.approveMilestone(jobId, 0);
        vm.expectRevert();
        hook.approveMilestone(jobId, 0);
        vm.stopPrank();
    }

    function test_complete_blockedUntilAllMilestonesApproved() public {
        _configureThreeMilestones();
        vm.startPrank(evaluator);
        hook.approveMilestone(jobId, 0);
        hook.approveMilestone(jobId, 1);
        vm.stopPrank();
        // Only 2 of 3 approved, complete should revert
        vm.expectRevert();
        commerce.complete(jobId, bytes32("done"), "");
    }

    function test_complete_succeedsAfterAllApproved() public {
        _configureThreeMilestones();
        vm.startPrank(evaluator);
        hook.approveMilestone(jobId, 0);
        hook.approveMilestone(jobId, 1);
        hook.approveMilestone(jobId, 2);
        vm.stopPrank();
        commerce.complete(jobId, bytes32("done"), "");
    }
}
