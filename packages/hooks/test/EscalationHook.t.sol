// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {EscalationHook} from "../src/EscalationHook.sol";
import {MockAgenticCommerce} from "./mocks/MockAgenticCommerce.sol";

contract EscalationHookTest is Test {
    MockAgenticCommerce internal commerce;
    EscalationHook internal hook;

    address internal client = makeAddr("client");
    address internal provider = makeAddr("provider");
    address internal evaluator = makeAddr("evaluator");
    address internal arbiter = makeAddr("arbiter");

    uint256 internal jobId;

    function setUp() public {
        commerce = new MockAgenticCommerce(address(0));
        hook = new EscalationHook(address(commerce), arbiter);
        vm.prank(client);
        jobId = commerce.createJob(provider, evaluator, block.timestamp + 1 days, "task", address(hook));
    }

    function test_initialStatusIsNone() public view {
        assertEq(uint256(hook.status(jobId)), uint256(EscalationHook.Status.None));
    }

    function test_completeAllowedWhenNotEscalated() public {
        commerce.complete(jobId, bytes32("ok"), "");
        // No revert
    }

    function test_escalate_setsStatusEscalated() public {
        vm.prank(client);
        hook.escalate(jobId);
        assertEq(uint256(hook.status(jobId)), uint256(EscalationHook.Status.Escalated));
    }

    function test_escalate_revertsIfNotClient() public {
        vm.prank(provider);
        vm.expectRevert();
        hook.escalate(jobId);
    }

    function test_escalate_cannotBeCalledTwice() public {
        vm.startPrank(client);
        hook.escalate(jobId);
        vm.expectRevert();
        hook.escalate(jobId);
        vm.stopPrank();
    }

    function test_complete_blockedAfterEscalation() public {
        vm.prank(client);
        hook.escalate(jobId);
        vm.expectRevert();
        commerce.complete(jobId, bytes32("ok"), "");
    }

    function test_reject_blockedDuringEscalation() public {
        vm.prank(client);
        hook.escalate(jobId);
        vm.prank(evaluator);
        vm.expectRevert();
        commerce.reject(jobId, bytes32("bad"), "");
    }

    function test_arbiterRule_approve_unblocksComplete() public {
        vm.prank(client);
        hook.escalate(jobId);
        vm.prank(arbiter);
        hook.rule(jobId, true, bytes32("provider correct"));
        assertEq(uint256(hook.status(jobId)), uint256(EscalationHook.Status.ResolvedApprove));
        commerce.complete(jobId, bytes32("ok"), "");
    }

    function test_arbiterRule_reject_keepsCompleteBlocked() public {
        vm.prank(client);
        hook.escalate(jobId);
        vm.prank(arbiter);
        hook.rule(jobId, false, bytes32("client correct"));
        assertEq(uint256(hook.status(jobId)), uint256(EscalationHook.Status.ResolvedReject));
        vm.expectRevert();
        commerce.complete(jobId, bytes32("ok"), "");
    }

    function test_rule_revertsForNonArbiter() public {
        vm.prank(client);
        hook.escalate(jobId);
        vm.prank(client);
        vm.expectRevert(abi.encodeWithSelector(EscalationHook.NotArbiter.selector, client));
        hook.rule(jobId, true, bytes32(""));
    }

    function test_rule_revertsIfNotEscalated() public {
        vm.prank(arbiter);
        vm.expectRevert(abi.encodeWithSelector(EscalationHook.NotEscalated.selector, jobId));
        hook.rule(jobId, true, bytes32(""));
    }
}
