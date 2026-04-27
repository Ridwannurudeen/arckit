// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TimeDecayReputationHook} from "../src/TimeDecayReputationHook.sol";
import {MockAgenticCommerce} from "./mocks/MockAgenticCommerce.sol";

contract TimeDecayReputationHookTest is Test {
    MockAgenticCommerce internal commerce;
    TimeDecayReputationHook internal hook;

    address internal client = makeAddr("client");
    address internal provider = makeAddr("provider");
    address internal evaluator = makeAddr("evaluator");

    function setUp() public {
        commerce = new MockAgenticCommerce(address(0));
        hook = new TimeDecayReputationHook(address(commerce));
    }

    function _createJob() internal returns (uint256) {
        vm.prank(client);
        return commerce.createJob(provider, evaluator, block.timestamp + 1 days, "task", address(hook));
    }

    function test_complete_recordsPositiveScore() public {
        uint256 jobId = _createJob();
        commerce.complete(jobId, bytes32("ok"), "");
        TimeDecayReputationHook.Record[] memory recs = hook.getRecords(provider);
        assertEq(recs.length, 1);
        assertEq(recs[0].score, hook.DEFAULT_COMPLETE_SCORE());
    }

    function test_reject_recordsNegativeScore() public {
        uint256 jobId = _createJob();
        vm.prank(evaluator);
        commerce.reject(jobId, bytes32("bad"), "");
        TimeDecayReputationHook.Record[] memory recs = hook.getRecords(provider);
        assertEq(recs.length, 1);
        assertEq(recs[0].score, hook.DEFAULT_REJECT_SCORE());
    }

    function test_decayedScore_freshScoreFullyCounted() public {
        uint256 jobId = _createJob();
        commerce.complete(jobId, bytes32("ok"), "");
        int256 score = hook.decayedScore(provider, 30 days);
        assertEq(score, 100);
    }

    function test_decayedScore_oneHalflifeHalves() public {
        uint256 jobId = _createJob();
        commerce.complete(jobId, bytes32("ok"), "");
        vm.warp(block.timestamp + 30 days);
        int256 score = hook.decayedScore(provider, 30 days);
        assertEq(score, 50);
    }

    function test_decayedScore_twoHalflivesQuarter() public {
        uint256 jobId = _createJob();
        commerce.complete(jobId, bytes32("ok"), "");
        vm.warp(block.timestamp + 60 days);
        int256 score = hook.decayedScore(provider, 30 days);
        assertEq(score, 25);
    }

    function test_decayedScore_aggregatesMultipleRecords() public {
        uint256 j1 = _createJob();
        commerce.complete(j1, bytes32("ok"), "");
        uint256 j2 = _createJob();
        commerce.complete(j2, bytes32("ok"), "");
        int256 score = hook.decayedScore(provider, 30 days);
        assertEq(score, 200);
    }

    function test_recordCount_tracksHistory() public {
        uint256 j1 = _createJob();
        commerce.complete(j1, bytes32("ok"), "");
        uint256 j2 = _createJob();
        vm.prank(evaluator);
        commerce.reject(j2, bytes32("bad"), "");
        assertEq(hook.recordCount(provider), 2);
    }

    function test_externalCallToAfterAction_reverts() public {
        vm.expectRevert();
        hook.afterAction(0, bytes4(keccak256("complete(uint256,bytes32,bytes)")), "");
    }
}
