// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseHook} from "./BaseHook.sol";
import {IAgenticCommerce} from "./interfaces/IAgenticCommerce.sol";

/// @title IStableSwap
/// @notice Minimal interface for an on-chain swap router that converts
///         alternative stablecoins to USDC (e.g. Circle StableFX, Curve, Uniswap).
interface IStableSwap {
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minOut, address recipient)
        external
        returns (uint256 amountOut);
}

/// @title MultiStablecoinHook
/// @notice ERC-8183 helper that lets a client fund a job with a non-USDC
///         stablecoin (e.g. BRLA, PHPC, JPYC, QCAD). The hook pulls the input
///         stablecoin, swaps it to USDC via a configured router, approves the
///         AgenticCommerce contract, and calls fund() on behalf of the client.
///
/// @dev    This hook is a wrapper helper rather than a strict gating hook. Set
///         the AgenticCommerce job's hook field to address(this) for compatibility
///         (beforeAction/afterAction are no-ops). The actual stablecoin handling
///         happens through the helper function fundWithStable.
contract MultiStablecoinHook is BaseHook {
    using SafeERC20 for IERC20;

    IStableSwap public immutable router;
    IERC20 public immutable usdc;

    /// @notice Tracks which stablecoin a client used to fund a given job.
    mapping(uint256 jobId => address currency) public jobCurrency;

    event FundedWithStable(
        uint256 indexed jobId,
        address indexed client,
        address indexed currency,
        uint256 amountIn,
        uint256 amountOutUsdc
    );

    error InvalidCurrency();
    error SlippageExceeded(uint256 received, uint256 minOut);

    constructor(address _agenticCommerce, address _router, address _usdc) BaseHook(_agenticCommerce) {
        router = IStableSwap(_router);
        usdc = IERC20(_usdc);
    }

    /// @notice Pull `amountIn` of `currency` from the caller, swap to USDC,
    ///         approve AgenticCommerce, and fund the job.
    /// @param  jobId    The ERC-8183 job to fund.
    /// @param  currency The non-USDC stablecoin the client wants to pay with.
    /// @param  amountIn Amount of `currency` the client is paying.
    /// @param  minUsdcOut Minimum USDC the client will accept after the swap.
    function fundWithStable(uint256 jobId, address currency, uint256 amountIn, uint256 minUsdcOut) external {
        if (currency == address(0) || currency == address(usdc)) revert InvalidCurrency();
        _requireClient(jobId, msg.sender);

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(currency).forceApprove(address(router), amountIn);
        uint256 received = router.swap(currency, amountIn, address(usdc), minUsdcOut, address(this));
        if (received < minUsdcOut) revert SlippageExceeded(received, minUsdcOut);

        usdc.forceApprove(address(agenticCommerce), received);
        // Forward call to AgenticCommerce.fund — note this hook now becomes
        // msg.sender for AgenticCommerce. The job's escrow is paid from this hook's
        // USDC balance via the prior approve.
        agenticCommerce.fund(jobId, "");

        jobCurrency[jobId] = currency;
        emit FundedWithStable(jobId, msg.sender, currency, amountIn, received);
    }

    /// @inheritdoc BaseHook
    function beforeAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }

    /// @inheritdoc BaseHook
    function afterAction(uint256, bytes4, bytes calldata) external view override onlyAgenticCommerce {
        // no-op
    }
}
