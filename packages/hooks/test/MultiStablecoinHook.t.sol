// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {IStableSwap, MultiStablecoinHook} from "../src/MultiStablecoinHook.sol";
import {MockAgenticCommerce} from "./mocks/MockAgenticCommerce.sol";

contract MockStable is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @notice 1:1 swap router used only for testing slippage and approval flow.
contract MockSwapRouter is IStableSwap {
    function swap(address tokenIn, uint256 amountIn, address tokenOut, uint256 minOut, address recipient)
        external
        override
        returns (uint256)
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // 1:1 swap (mock)
        require(amountIn >= minOut, "slippage");
        MockStable(tokenOut).mint(recipient, amountIn);
        return amountIn;
    }
}

contract MultiStablecoinHookTest is Test {
    MockAgenticCommerce internal commerce;
    MultiStablecoinHook internal hook;
    MockStable internal usdc;
    MockStable internal brla;
    MockSwapRouter internal router;

    address internal client = makeAddr("client");
    address internal provider = makeAddr("provider");
    address internal evaluator = makeAddr("evaluator");

    uint256 internal jobId;

    function setUp() public {
        usdc = new MockStable("USD Coin", "USDC");
        brla = new MockStable("Brazilian Real", "BRLA");
        router = new MockSwapRouter();
        commerce = new MockAgenticCommerce(address(usdc));
        hook = new MultiStablecoinHook(address(commerce), address(router), address(usdc));

        vm.prank(client);
        jobId = commerce.createJob(provider, evaluator, block.timestamp + 1 days, "fx job", address(hook));
    }

    function test_fundWithStable_swapsAndFunds() public {
        brla.mint(client, 100 ether);
        vm.startPrank(client);
        brla.approve(address(hook), 100 ether);
        hook.fundWithStable(jobId, address(brla), 100 ether, 95 ether);
        vm.stopPrank();
        assertEq(hook.jobCurrency(jobId), address(brla));
    }

    function test_fundWithStable_revertsForUSDC() public {
        usdc.mint(client, 100 ether);
        vm.startPrank(client);
        usdc.approve(address(hook), 100 ether);
        vm.expectRevert(MultiStablecoinHook.InvalidCurrency.selector);
        hook.fundWithStable(jobId, address(usdc), 100 ether, 100 ether);
        vm.stopPrank();
    }

    function test_fundWithStable_revertsForZeroAddress() public {
        vm.prank(client);
        vm.expectRevert(MultiStablecoinHook.InvalidCurrency.selector);
        hook.fundWithStable(jobId, address(0), 100, 100);
    }

    function test_fundWithStable_onlyClientCanCall() public {
        brla.mint(provider, 100 ether);
        vm.startPrank(provider);
        brla.approve(address(hook), 100 ether);
        vm.expectRevert();
        hook.fundWithStable(jobId, address(brla), 100 ether, 95 ether);
        vm.stopPrank();
    }
}
