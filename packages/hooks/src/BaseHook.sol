// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IACPHook} from "./interfaces/IACPHook.sol";
import {IAgenticCommerce} from "./interfaces/IAgenticCommerce.sol";

/// @title BaseHook
/// @notice Base contract for ERC-8183 IACPHook implementations. Provides
///         immutable AgenticCommerce binding, action selector constants,
///         caller authentication, and ERC-165 wiring.
abstract contract BaseHook is ERC165, IACPHook {
    /// @notice The canonical AgenticCommerce contract this hook is bound to.
    IAgenticCommerce public immutable agenticCommerce;

    // ── Action selectors (precomputed for gas) ──
    bytes4 internal constant SELECTOR_CREATE_JOB =
        bytes4(keccak256("createJob(address,address,uint256,string,address)"));
    bytes4 internal constant SELECTOR_SET_BUDGET = bytes4(keccak256("setBudget(uint256,uint256,bytes)"));
    bytes4 internal constant SELECTOR_FUND = bytes4(keccak256("fund(uint256,bytes)"));
    bytes4 internal constant SELECTOR_SUBMIT = bytes4(keccak256("submit(uint256,bytes32,bytes)"));
    bytes4 internal constant SELECTOR_COMPLETE = bytes4(keccak256("complete(uint256,bytes32,bytes)"));
    bytes4 internal constant SELECTOR_REJECT = bytes4(keccak256("reject(uint256,bytes32,bytes)"));

    error UnauthorizedCaller(address caller);
    error UnauthorizedActor(address actor, address expected);

    constructor(address _agenticCommerce) {
        agenticCommerce = IAgenticCommerce(_agenticCommerce);
    }

    /// @dev Restricts a function so only the AgenticCommerce contract can call it.
    modifier onlyAgenticCommerce() {
        if (msg.sender != address(agenticCommerce)) revert UnauthorizedCaller(msg.sender);
        _;
    }

    /// @dev Reverts unless `actor` is the client of the given job.
    function _requireClient(uint256 jobId, address actor) internal view {
        address client = agenticCommerce.getJob(jobId).client;
        if (actor != client) revert UnauthorizedActor(actor, client);
    }

    /// @dev Reverts unless `actor` is the evaluator of the given job.
    function _requireEvaluator(uint256 jobId, address actor) internal view {
        address evaluator = agenticCommerce.getJob(jobId).evaluator;
        if (actor != evaluator) revert UnauthorizedActor(actor, evaluator);
    }

    /// @dev Reverts unless `actor` is the provider of the given job.
    function _requireProvider(uint256 jobId, address actor) internal view {
        address provider = agenticCommerce.getJob(jobId).provider;
        if (actor != provider) revert UnauthorizedActor(actor, provider);
    }

    /// @inheritdoc IACPHook
    function beforeAction(uint256 jobId, bytes4 selector, bytes calldata data) external virtual;

    /// @inheritdoc IACPHook
    function afterAction(uint256 jobId, bytes4 selector, bytes calldata data) external virtual;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IACPHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
