// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IAgenticCommerce
/// @notice Interface for the canonical ERC-8183 AgenticCommerce contract on Arc.
/// @dev    Arc testnet deployment: 0x0747EEf0706327138c69792bF28Cd525089e4583
interface IAgenticCommerce {
    enum JobStatus {
        Open,
        Funded,
        Submitted,
        Completed,
        Rejected,
        Expired
    }

    struct Job {
        uint256 id;
        address client;
        address provider;
        address evaluator;
        string description;
        uint256 budget;
        uint256 expiredAt;
        JobStatus status;
        address hook;
    }

    /// @notice Create a new job in Open state.
    function createJob(
        address provider,
        address evaluator,
        uint256 expiredAt,
        string calldata description,
        address hook
    ) external returns (uint256);

    /// @notice Provider sets the price for the job.
    function setBudget(uint256 jobId, uint256 amount, bytes calldata optParams) external;

    /// @notice Client escrows the agreed budget.
    function fund(uint256 jobId, bytes calldata optParams) external;

    /// @notice Provider submits the deliverable.
    function submit(uint256 jobId, bytes32 deliverable, bytes calldata optParams) external;

    /// @notice Evaluator accepts the deliverable and releases payment.
    function complete(uint256 jobId, bytes32 reason, bytes calldata optParams) external;

    /// @notice Evaluator rejects the deliverable.
    function reject(uint256 jobId, bytes32 reason, bytes calldata optParams) external;

    /// @notice Client claims a refund on an expired or rejected job.
    function claimRefund(uint256 jobId) external;

    /// @notice Read full job state.
    function getJob(uint256 jobId) external view returns (Job memory);

    /// @notice Total number of jobs created.
    function jobCounter() external view returns (uint256);

    /// @notice Address of the ERC-20 token used for escrow (USDC on Arc).
    function paymentToken() external view returns (address);
}
