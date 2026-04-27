// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title IACPHook
/// @notice Interface for ERC-8183 AgenticCommerce hooks. Hooks are called by the
///         AgenticCommerce contract before and after key job actions, enabling
///         custom evaluation, dispute, milestone, and reputation logic.
/// @dev    Implementations must support ERC-165 via supportsInterface.
interface IACPHook is IERC165 {
    /// @notice Called before a job action executes (createJob, fund, submit, complete, reject).
    /// @param  jobId    The ID of the job being acted on.
    /// @param  selector The function selector of the action being performed.
    /// @param  data     ABI-encoded action-specific data.
    function beforeAction(uint256 jobId, bytes4 selector, bytes calldata data) external;

    /// @notice Called after a job action completes.
    /// @param  jobId    The ID of the job being acted on.
    /// @param  selector The function selector of the action being performed.
    /// @param  data     ABI-encoded action-specific data.
    function afterAction(uint256 jobId, bytes4 selector, bytes calldata data) external;
}
