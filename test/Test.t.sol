// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/OneToOneSwap.sol";
import "../src/TestToken.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract OneToOneSwapTest is Test {
    OneToOneSwap public swap;
    TestToken public tokenA;
    TestToken public tokenB;
    address public admin;

    function setUp() public {
        admin = address(this); // Use the current contract address as the admin
        tokenA = new TestToken("TokenA", "TKA");
        tokenB = new TestToken("TokenB", "TKB");

        swap = new OneToOneSwap(address(tokenA), address(tokenB));
        // No need to grant roles explicitly now as the constructor does this

        // Log the admin role
        console.logBytes32(swap.ADMIN_ROLE());

        // Mint some tokens to admin for adding liquidity
        tokenA.mint(admin, 1000 * 10**18);
        tokenB.mint(admin, 1000 * 10**18);
    }

    function testAddLiquidity() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);

        assertEq(tokenA.balanceOf(address(swap)), 100 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 100 * 10**18);

        vm.stopPrank();
    }

    function testAddLiquidityTwice() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 150 * 10**18);
        tokenB.approve(address(swap), 150 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        swap.addLiquidity(50 * 10**18, 50 * 10**18);

        assertEq(tokenA.balanceOf(address(swap)), 150 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 150 * 10**18);

        vm.stopPrank();
    }

    function testAddLiquidityInsufficientApproval() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 50 * 10**18);
        tokenB.approve(address(swap), 50 * 10**18);

        vm.expectRevert();
        swap.addLiquidity(100 * 10**18, 100 * 10**18);

        vm.stopPrank();
    }
 
    function testAddLiquidityWithNoAdminRole() public {
        address nonAdmin = address(0x2);
        vm.startPrank(nonAdmin);

        tokenA.mint(nonAdmin, 100 * 10**18);
        tokenB.mint(nonAdmin, 100 * 10**18);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        vm.expectRevert();
        swap.addLiquidity(100 * 10**18, 100 * 10**18);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        swap.removeLiquidity(50 * 10**18, 50 * 10**18);

        assertEq(tokenA.balanceOf(address(swap)), 50 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 50 * 10**18);
        assertEq(tokenA.balanceOf(admin), 950 * 10**18);
        assertEq(tokenB.balanceOf(admin), 950 * 10**18);

        vm.stopPrank();
    }

    function testRemoveAllLiquidity() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        swap.removeLiquidity(100 * 10**18, 100 * 10**18);

        assertEq(tokenA.balanceOf(address(swap)), 0);
        assertEq(tokenB.balanceOf(address(swap)), 0);
        assertEq(tokenA.balanceOf(admin), 1000 * 10**18);
        assertEq(tokenB.balanceOf(admin), 1000 * 10**18);

        vm.stopPrank();
    }

    function testRemoveLiquidityInsufficientBalance() public {
        vm.startPrank(admin);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);

        vm.expectRevert();
        swap.removeLiquidity(150 * 10**18, 150 * 10**18);

        vm.stopPrank();
    }

    function testRemoveLiquidityWithNoAdminRole() public {
        address nonAdmin = address(0x2);
        vm.startPrank(admin);

        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);

        swap.addLiquidity(100 * 10**18, 100 * 10**18);

        vm.stopPrank();

        vm.startPrank(nonAdmin);
        vm.expectRevert();
        swap.removeLiquidity(50 * 10**18, 50 * 10**18);

        vm.stopPrank();
    }

    function testSwap() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA.mint(user, 10 * 10**18);
        tokenA.approve(address(swap), 10 * 10**18);

        swap.swap(address(tokenA), 10 * 10**18);

        assertEq(tokenA.balanceOf(user), 0);
        assertEq(tokenB.balanceOf(user), 10 * 10**18);
        assertEq(tokenA.balanceOf(address(swap)), 110 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 90 * 10**18);

        vm.stopPrank();
    }

    function testSwapReverse() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenB.mint(user, 10 * 10**18);
        tokenB.approve(address(swap), 10 * 10**18);

        swap.swap(address(tokenB), 10 * 10**18);

        assertEq(tokenB.balanceOf(user), 0);
        assertEq(tokenA.balanceOf(user), 10 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 110 * 10**18);
        assertEq(tokenA.balanceOf(address(swap)), 90 * 10**18);

        vm.stopPrank();
    }

    function testSwapInsufficientLiquidity() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA.mint(user, 200 * 10**18);
        tokenA.approve(address(swap), 200 * 10**18);

        vm.expectRevert("Insufficient liquidity");
        swap.swap(address(tokenA), 200 * 10**18);

        vm.stopPrank();
    }

    function testSwapWithNoTokens() public {
        address user = address(0x2);

        vm.startPrank(user);

        vm.expectRevert("Insufficient liquidity");
        swap.swap(address(tokenA), 10 * 10**18);

        vm.stopPrank();
    }

    function testSwapWithInvalidToken() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA.mint(user, 10 * 10**18);
        tokenA.approve(address(swap), 10 * 10**18);

        vm.expectRevert("Invalid token");
        swap.swap(address(0x3), 10 * 10**18);

        vm.stopPrank();
    }

    function testSwapTwice() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA.mint(user, 10 * 10**18);
        tokenA.approve(address(swap), 10 * 10**18);
        swap.swap(address(tokenA), 10 * 10**18);

        tokenA.mint(user, 5 * 10**18);
        tokenA.approve(address(swap), 5 * 10**18);
        swap.swap(address(tokenA), 5 * 10**18);

        assertEq(tokenA.balanceOf(user), 0);
        assertEq(tokenB.balanceOf(user), 15 * 10**18);
        assertEq(tokenA.balanceOf(address(swap)), 115 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 85 * 10**18);

        vm.stopPrank();
    }
}
