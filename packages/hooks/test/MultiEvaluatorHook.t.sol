// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MultiEvaluatorHook} from "../src/MultiEvaluatorHook.sol";
import {MockAgenticCommerce} from "./mocks/MockAgenticCommerce.sol";

contract MultiEvaluatorHookTest is Test {
    MockAgenticCommerce internal commerce;
    MultiEvaluatorHook internal hook;

    address internal client = makeAddr("client");
    address internal provider = makeAddr("provider");
    address internal nominalEval = makeAddr("nominalEval");
    address internal eval1 = makeAddr("eval1");
    address internal eval2 = makeAddr("eval2");
    address internal eval3 = makeAddr("eval3");

    uint256 internal jobId;

    function setUp() public {
        commerce = new MockAgenticCommerce(address(0));
        hook = new MultiEvaluatorHook(address(commerce));

        vm.prank(client);
        jobId = commerce.createJob(provider, nominalEval, block.timestamp + 1 days, "audit", address(hook));
    }

    function _configureThreshold2of3() internal {
        address[] memory evals = new address[](3);
        evals[0] = eval1;
        evals[1] = eval2;
        evals[2] = eval3;
        vm.prank(client);
        hook.configure(jobId, evals, 2);
    }

    function test_configure_setsThresholdAndEvaluators() public {
        _configureThreshold2of3();
        (uint256 threshold, bool init) = hook.configs(jobId);
        assertEq(threshold, 2);
        assertTrue(init);
        assertTrue(hook.isEvaluator(jobId, eval1));
        assertTrue(hook.isEvaluator(jobId, eval2));
        assertTrue(hook.isEvaluator(jobId, eval3));
        assertEq(hook.getEvaluators(jobId).length, 3);
    }

    function test_configure_revertsIfNotClient() public {
        address[] memory evals = new address[](1);
        evals[0] = eval1;
        vm.prank(provider);
        vm.expectRevert();
        hook.configure(jobId, evals, 1);
    }

    function test_configure_revertsOnZeroThreshold() public {
        address[] memory evals = new address[](2);
        evals[0] = eval1;
        evals[1] = eval2;
        vm.prank(client);
        vm.expectRevert(abi.encodeWithSelector(MultiEvaluatorHook.InvalidThreshold.selector, 0, 2));
        hook.configure(jobId, evals, 0);
    }

    function test_configure_revertsOnThresholdAboveCount() public {
        address[] memory evals = new address[](2);
        evals[0] = eval1;
        evals[1] = eval2;
        vm.prank(client);
        vm.expectRevert(abi.encodeWithSelector(MultiEvaluatorHook.InvalidThreshold.selector, 5, 2));
        hook.configure(jobId, evals, 5);
    }

    function test_configure_cannotBeCalledTwice() public {
        _configureThreshold2of3();
        address[] memory evals = new address[](1);
        evals[0] = eval1;
        vm.prank(client);
        vm.expectRevert(abi.encodeWithSelector(MultiEvaluatorHook.AlreadyConfigured.selector, jobId));
        hook.configure(jobId, evals, 1);
    }

    function test_vote_recordsApproval() public {
        _configureThreshold2of3();
        vm.prank(eval1);
        hook.vote(jobId, true);
        assertEq(hook.approvalCount(jobId), 1);
        assertTrue(hook.hasVoted(jobId, eval1));
    }

    function test_vote_recordsRejection() public {
        _configureThreshold2of3();
        vm.prank(eval1);
        hook.vote(jobId, false);
        assertEq(hook.rejectionCount(jobId), 1);
    }

    function test_vote_revertsForNonEvaluator() public {
        _configureThreshold2of3();
        vm.prank(makeAddr("randomActor"));
        vm.expectRevert();
        hook.vote(jobId, true);
    }

    function test_vote_cannotDoubleVote() public {
        _configureThreshold2of3();
        vm.prank(eval1);
        hook.vote(jobId, true);
        vm.prank(eval1);
        vm.expectRevert(abi.encodeWithSelector(MultiEvaluatorHook.AlreadyVoted.selector, jobId, eval1));
        hook.vote(jobId, true);
    }

    function test_complete_blockedBeforeQuorum() public {
        _configureThreshold2of3();
        vm.prank(eval1);
        hook.vote(jobId, true);
        // 1 approval, threshold 2 — complete should revert
        vm.expectRevert();
        commerce.complete(jobId, bytes32("ok"), "");
    }

    function test_complete_succeedsAtQuorum() public {
        _configureThreshold2of3();
        vm.prank(eval1);
        hook.vote(jobId, true);
        vm.prank(eval2);
        hook.vote(jobId, true);
        assertTrue(hook.quorumReached(jobId));

        commerce.complete(jobId, bytes32("ok"), "");
        // No revert means hook approved.
    }

    function test_complete_revertsIfHookNotConfigured() public {
        vm.expectRevert(abi.encodeWithSelector(MultiEvaluatorHook.NotConfigured.selector, jobId));
        commerce.complete(jobId, bytes32("ok"), "");
    }

    function test_beforeAction_revertsForExternalCallers() public {
        _configureThreshold2of3();
        vm.expectRevert();
        hook.beforeAction(jobId, bytes4(keccak256("complete(uint256,bytes32,bytes)")), "");
    }
}
