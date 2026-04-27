// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseHook} from "./BaseHook.sol";

/// @title MultiEvaluatorHook
/// @notice ERC-8183 hook that requires N-of-M evaluators to approve before a job
///         can be completed. The job creator (client) configures the evaluator
///         set and threshold immediately after createJob.
///
/// @dev    Usage:
///   1. Client calls AgenticCommerce.createJob(..., hook: address(MultiEvaluatorHook))
///   2. Client calls hook.configure(jobId, evaluators[], threshold)
///   3. Provider does setBudget + submit as normal
///   4. Each registered evaluator calls hook.vote(jobId, approve)
///   5. Once threshold approvals collected, the job's nominal evaluator (or any
///      evaluator) calls AgenticCommerce.complete(jobId, ...) — hook allows it
contract MultiEvaluatorHook is BaseHook {
    struct Config {
        uint256 threshold;
        bool initialized;
    }

    mapping(uint256 jobId => Config) public configs;
    mapping(uint256 jobId => address[]) private _evaluators;
    mapping(uint256 jobId => mapping(address evaluator => bool)) public isEvaluator;
    mapping(uint256 jobId => mapping(address evaluator => bool)) public hasVoted;
    mapping(uint256 jobId => uint256) public approvalCount;
    mapping(uint256 jobId => uint256) public rejectionCount;

    event Configured(uint256 indexed jobId, address[] evaluators, uint256 threshold);
    event Voted(uint256 indexed jobId, address indexed evaluator, bool approve);

    error AlreadyConfigured(uint256 jobId);
    error InvalidThreshold(uint256 threshold, uint256 evaluatorCount);
    error NotConfigured(uint256 jobId);
    error AlreadyVoted(uint256 jobId, address evaluator);
    error QuorumNotReached(uint256 jobId, uint256 approvals, uint256 threshold);

    constructor(address _agenticCommerce) BaseHook(_agenticCommerce) {}

    /// @notice Configure the evaluator set and approval threshold for a job.
    ///         Must be called by the job's client after createJob.
    function configure(uint256 jobId, address[] calldata evaluators, uint256 threshold) external {
        _requireClient(jobId, msg.sender);
        if (configs[jobId].initialized) revert AlreadyConfigured(jobId);
        if (threshold == 0 || threshold > evaluators.length) {
            revert InvalidThreshold(threshold, evaluators.length);
        }

        configs[jobId] = Config({threshold: threshold, initialized: true});
        for (uint256 i = 0; i < evaluators.length; i++) {
            _evaluators[jobId].push(evaluators[i]);
            isEvaluator[jobId][evaluators[i]] = true;
        }

        emit Configured(jobId, evaluators, threshold);
    }

    /// @notice Cast a vote on a job. Each evaluator may vote at most once.
    function vote(uint256 jobId, bool approve) external {
        if (!configs[jobId].initialized) revert NotConfigured(jobId);
        if (!isEvaluator[jobId][msg.sender]) revert UnauthorizedActor(msg.sender, address(0));
        if (hasVoted[jobId][msg.sender]) revert AlreadyVoted(jobId, msg.sender);

        hasVoted[jobId][msg.sender] = true;
        if (approve) {
            approvalCount[jobId]++;
        } else {
            rejectionCount[jobId]++;
        }
        emit Voted(jobId, msg.sender, approve);
    }

    /// @notice Returns the configured evaluators for a job.
    function getEvaluators(uint256 jobId) external view returns (address[] memory) {
        return _evaluators[jobId];
    }

    /// @notice Returns true if the job has reached its approval threshold.
    function quorumReached(uint256 jobId) public view returns (bool) {
        return approvalCount[jobId] >= configs[jobId].threshold;
    }

    /// @inheritdoc BaseHook
    function beforeAction(uint256 jobId, bytes4 selector, bytes calldata) external view override onlyAgenticCommerce {
        if (selector == SELECTOR_COMPLETE) {
            if (!configs[jobId].initialized) revert NotConfigured(jobId);
            if (!quorumReached(jobId)) {
                revert QuorumNotReached(jobId, approvalCount[jobId], configs[jobId].threshold);
            }
        }
    }

    /// @inheritdoc BaseHook
    function afterAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }
}
