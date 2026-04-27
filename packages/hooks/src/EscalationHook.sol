// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseHook} from "./BaseHook.sol";

/// @title EscalationHook
/// @notice ERC-8183 hook that introduces single-arbiter dispute escalation.
///         If the evaluator rejects a deliverable, the client may escalate to a
///         neutral arbiter (set at deployment). The arbiter's ruling is final
///         and gates the next valid action: complete (if approved) or claimRefund.
///
/// @dev    The hook does not move funds; it only gates state transitions.
///         To finalize after an arbiter approval the job's evaluator (or anyone
///         the AgenticCommerce contract permits) must call complete().
contract EscalationHook is BaseHook {
    enum Status {
        None, // never escalated
        Escalated, // client opened a dispute, arbiter has not ruled
        ResolvedApprove, // arbiter ruled in favor of provider (allow complete)
        ResolvedReject // arbiter ruled in favor of client (allow refund only)

    }

    address public immutable arbiter;
    mapping(uint256 jobId => Status) public status;
    mapping(uint256 jobId => bytes32) public arbiterReason;

    event Escalated(uint256 indexed jobId, address indexed client);
    event Ruled(uint256 indexed jobId, bool approve, bytes32 reason);

    error NotArbiter(address caller);
    error AlreadyEscalated(uint256 jobId);
    error NotEscalated(uint256 jobId);
    error AwaitingRuling(uint256 jobId);

    constructor(address _agenticCommerce, address _arbiter) BaseHook(_agenticCommerce) {
        arbiter = _arbiter;
    }

    /// @notice Open a dispute. Only the client may call, and only after the
    ///         provider has submitted (job status >= Submitted).
    function escalate(uint256 jobId) external {
        _requireClient(jobId, msg.sender);
        if (status[jobId] != Status.None) revert AlreadyEscalated(jobId);
        status[jobId] = Status.Escalated;
        emit Escalated(jobId, msg.sender);
    }

    /// @notice Arbiter rules on an escalated dispute.
    function rule(uint256 jobId, bool approve, bytes32 reason) external {
        if (msg.sender != arbiter) revert NotArbiter(msg.sender);
        if (status[jobId] != Status.Escalated) revert NotEscalated(jobId);
        status[jobId] = approve ? Status.ResolvedApprove : Status.ResolvedReject;
        arbiterReason[jobId] = reason;
        emit Ruled(jobId, approve, reason);
    }

    /// @inheritdoc BaseHook
    function beforeAction(uint256 jobId, bytes4 selector, bytes calldata) external view override onlyAgenticCommerce {
        Status s = status[jobId];

        if (selector == SELECTOR_COMPLETE) {
            // Once escalated, only allow complete after arbiter approves.
            if (s == Status.Escalated) revert AwaitingRuling(jobId);
            if (s == Status.ResolvedReject) revert AwaitingRuling(jobId);
        } else if (selector == SELECTOR_REJECT) {
            // Cannot reject while a ruling is pending or after arbiter approves.
            if (s == Status.Escalated || s == Status.ResolvedApprove) revert AwaitingRuling(jobId);
        }
    }

    /// @inheritdoc BaseHook
    function afterAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }
}
