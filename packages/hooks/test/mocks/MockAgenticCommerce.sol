// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IACPHook} from "../../src/interfaces/IACPHook.sol";
import {IAgenticCommerce} from "../../src/interfaces/IAgenticCommerce.sol";

/// @title MockAgenticCommerce
/// @notice Test double that mirrors the canonical AgenticCommerce job lifecycle
///         and forwards beforeAction/afterAction calls to a job's hook so that
///         the BaseHook.onlyAgenticCommerce check can be exercised in unit tests.
contract MockAgenticCommerce is IAgenticCommerce {
    uint256 private _counter;
    mapping(uint256 => Job) private _jobs;
    address public override paymentToken;

    constructor(address _paymentToken) {
        paymentToken = _paymentToken;
    }

    function jobCounter() external view override returns (uint256) {
        return _counter;
    }

    function getJob(uint256 jobId) external view override returns (Job memory) {
        return _jobs[jobId];
    }

    function createJob(
        address provider,
        address evaluator,
        uint256 expiredAt,
        string calldata description,
        address hook
    ) external override returns (uint256) {
        _counter++;
        uint256 id = _counter;
        _jobs[id] = Job({
            id: id,
            client: msg.sender,
            provider: provider,
            evaluator: evaluator,
            description: description,
            budget: 0,
            expiredAt: expiredAt,
            status: JobStatus.Open,
            hook: hook
        });
        return id;
    }

    function setBudget(uint256 jobId, uint256 amount, bytes calldata optParams) external override {
        Job storage j = _jobs[jobId];
        require(msg.sender == j.provider, "not provider");
        bytes4 selector = bytes4(keccak256("setBudget(uint256,uint256,bytes)"));
        if (j.hook != address(0)) IACPHook(j.hook).beforeAction(jobId, selector, optParams);
        j.budget = amount;
        if (j.hook != address(0)) IACPHook(j.hook).afterAction(jobId, selector, optParams);
    }

    function fund(uint256 jobId, bytes calldata optParams) external override {
        Job storage j = _jobs[jobId];
        bytes4 selector = bytes4(keccak256("fund(uint256,bytes)"));
        if (j.hook != address(0)) IACPHook(j.hook).beforeAction(jobId, selector, optParams);
        j.status = JobStatus.Funded;
        if (j.hook != address(0)) IACPHook(j.hook).afterAction(jobId, selector, optParams);
    }

    function submit(uint256 jobId, bytes32 deliverable, bytes calldata optParams) external override {
        Job storage j = _jobs[jobId];
        require(msg.sender == j.provider, "not provider");
        bytes4 selector = bytes4(keccak256("submit(uint256,bytes32,bytes)"));
        if (j.hook != address(0)) IACPHook(j.hook).beforeAction(jobId, selector, abi.encode(deliverable, optParams));
        j.status = JobStatus.Submitted;
        if (j.hook != address(0)) IACPHook(j.hook).afterAction(jobId, selector, abi.encode(deliverable, optParams));
    }

    function complete(uint256 jobId, bytes32 reason, bytes calldata optParams) external override {
        Job storage j = _jobs[jobId];
        bytes4 selector = bytes4(keccak256("complete(uint256,bytes32,bytes)"));
        if (j.hook != address(0)) IACPHook(j.hook).beforeAction(jobId, selector, abi.encode(reason, optParams));
        j.status = JobStatus.Completed;
        if (j.hook != address(0)) IACPHook(j.hook).afterAction(jobId, selector, abi.encode(reason, optParams));
    }

    function reject(uint256 jobId, bytes32 reason, bytes calldata optParams) external override {
        Job storage j = _jobs[jobId];
        require(msg.sender == j.evaluator, "not evaluator");
        bytes4 selector = bytes4(keccak256("reject(uint256,bytes32,bytes)"));
        if (j.hook != address(0)) IACPHook(j.hook).beforeAction(jobId, selector, abi.encode(reason, optParams));
        j.status = JobStatus.Rejected;
        if (j.hook != address(0)) IACPHook(j.hook).afterAction(jobId, selector, abi.encode(reason, optParams));
    }

    function claimRefund(uint256 jobId) external override {
        Job storage j = _jobs[jobId];
        j.status = JobStatus.Expired;
    }
}
