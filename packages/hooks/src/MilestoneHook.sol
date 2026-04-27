// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseHook} from "./BaseHook.sol";

/// @title MilestoneHook
/// @notice ERC-8183 hook that splits a job into discrete milestones. The
///         evaluator approves each milestone individually, and complete() is
///         only permitted once every milestone has been approved.
///
/// @dev    The hook does not split escrow on-chain — all funds remain in the
///         AgenticCommerce contract until complete(). The milestones are an
///         off-chain progress framework that the evaluator must honor before
///         releasing payment.
contract MilestoneHook is BaseHook {
    struct Milestone {
        bytes32 name;
        uint256 weight; // basis points of total job value (sum should = 10_000)
        bool approved;
    }

    mapping(uint256 jobId => Milestone[]) private _milestones;
    mapping(uint256 jobId => bool) public initialized;
    mapping(uint256 jobId => uint256) public approvedCount;

    event Configured(uint256 indexed jobId, bytes32[] names, uint256[] weights);
    event MilestoneApproved(uint256 indexed jobId, uint256 indexed index, bytes32 name);

    error AlreadyInitialized(uint256 jobId);
    error InvalidMilestoneSetup(string reason);
    error NotInitialized(uint256 jobId);
    error MilestoneAlreadyApproved(uint256 jobId, uint256 index);
    error MilestonesIncomplete(uint256 jobId, uint256 approved, uint256 total);

    constructor(address _agenticCommerce) BaseHook(_agenticCommerce) {}

    /// @notice Configure milestones. Only the client may call. Weights are in
    ///         basis points and must sum to 10_000.
    function configure(uint256 jobId, bytes32[] calldata names, uint256[] calldata weights) external {
        _requireClient(jobId, msg.sender);
        if (initialized[jobId]) revert AlreadyInitialized(jobId);
        if (names.length == 0) revert InvalidMilestoneSetup("empty");
        if (names.length != weights.length) revert InvalidMilestoneSetup("length mismatch");

        uint256 totalWeight;
        for (uint256 i = 0; i < names.length; i++) {
            totalWeight += weights[i];
            _milestones[jobId].push(Milestone({name: names[i], weight: weights[i], approved: false}));
        }
        if (totalWeight != 10_000) revert InvalidMilestoneSetup("weights must sum to 10000 bps");

        initialized[jobId] = true;
        emit Configured(jobId, names, weights);
    }

    /// @notice Mark a milestone as approved. Only the job's evaluator may call.
    function approveMilestone(uint256 jobId, uint256 index) external {
        _requireEvaluator(jobId, msg.sender);
        if (!initialized[jobId]) revert NotInitialized(jobId);
        if (index >= _milestones[jobId].length) revert InvalidMilestoneSetup("index out of bounds");
        if (_milestones[jobId][index].approved) revert MilestoneAlreadyApproved(jobId, index);

        _milestones[jobId][index].approved = true;
        approvedCount[jobId]++;
        emit MilestoneApproved(jobId, index, _milestones[jobId][index].name);
    }

    /// @notice Returns all milestones for a job.
    function getMilestones(uint256 jobId) external view returns (Milestone[] memory) {
        return _milestones[jobId];
    }

    /// @notice Returns the cumulative approved weight in basis points.
    function approvedWeight(uint256 jobId) external view returns (uint256 total) {
        Milestone[] memory ms = _milestones[jobId];
        for (uint256 i = 0; i < ms.length; i++) {
            if (ms[i].approved) total += ms[i].weight;
        }
    }

    /// @inheritdoc BaseHook
    function beforeAction(uint256 jobId, bytes4 selector, bytes calldata) external view override onlyAgenticCommerce {
        if (selector == SELECTOR_COMPLETE) {
            if (!initialized[jobId]) revert NotInitialized(jobId);
            uint256 total = _milestones[jobId].length;
            if (approvedCount[jobId] != total) {
                revert MilestonesIncomplete(jobId, approvedCount[jobId], total);
            }
        }
    }

    /// @inheritdoc BaseHook
    function afterAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }
}
