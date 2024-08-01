// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/OneToOneSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OneToOneSwapTest is Test {
    OneToOneSwap public swap;
    ERC20 public tokenA;
    ERC20 public tokenB;
    address public admin;

    function setUp() public {
        admin = address(0x1);
        tokenA = new ERC20("TokenA", "TKA");
        tokenB = new ERC20("TokenB", "TKB");

        swap = new OneToOneSwap(address(tokenA), address(tokenB));
        swap.grantRole(swap.ADMIN_ROLE(), admin);

        // Mint some tokens to admin for adding liquidity
        tokenA._mint(admin, 1000 * 10**18);
        tokenB._mint(admin, 1000 * 10**18);
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

    function testSwap() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA._mint(user, 10 * 10**18);
        tokenA.approve(address(swap), 10 * 10**18);

        swap.swap(address(tokenA), 10 * 10**18);

        assertEq(tokenA.balanceOf(user), 0);
        assertEq(tokenB.balanceOf(user), 10 * 10**18);
        assertEq(tokenA.balanceOf(address(swap)), 110 * 10**18);
        assertEq(tokenB.balanceOf(address(swap)), 90 * 10**18);

        vm.stopPrank();
    }

    function testSwapInvalidToken() public {
        address user = address(0x2);

        vm.startPrank(user);
        tokenA._mint(user, 10 * 10**18);
        tokenA.approve(address(swap), 10 * 10**18);

        vm.expectRevert("Invalid token");
        swap.swap(address(0x3), 10 * 10**18);

        vm.stopPrank();
    }

    function testInsufficientLiquidity() public {
        address user = address(0x2);

        vm.startPrank(admin);
        tokenA.approve(address(swap), 100 * 10**18);
        tokenB.approve(address(swap), 100 * 10**18);
        swap.addLiquidity(100 * 10**18, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        tokenA._mint(user, 200 * 10**18);
        tokenA.approve(address(swap), 200 * 10**18);

        vm.expectRevert("Insufficient liquidity");
        swap.swap(address(tokenA), 200 * 10**18);

        vm.stopPrank();
    }
}
