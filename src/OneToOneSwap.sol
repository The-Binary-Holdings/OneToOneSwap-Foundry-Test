// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title OneToOneSwap
 * @dev A contract for 1:1 token swaps without fees.
 */
contract OneToOneSwap is AccessControl, ReentrancyGuard {
    address public tokenA;
    address public tokenB;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @dev Emitted when tokens are swapped.
     * @param user The address of the user.
     * @param tokenIn The address of the token being swapped in.
     * @param tokenOut The address of the token being swapped out.
     * @param amount The amount of tokens swapped.
     */
    event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amount);

    /**
     * @dev Emitted when liquidity is added.
     * @param user The address of the user.
     * @param amountA The amount of tokenA added.
     * @param amountB The amount of tokenB added.
     */
    event AddLiquidity(address indexed user, uint256 amountA, uint256 amountB);

    /**
     * @dev Emitted when liquidity is removed.
     * @param user The address of the user.
     * @param amountA The amount of tokenA removed.
     * @param amountB The amount of tokenB removed.
     */
    event RemoveLiquidity(address indexed user, uint256 amountA, uint256 amountB);

    /**
     * @dev Initializes the contract with the addresses of the two tokens and sets up admin role.
     * @param _tokenA The address of tokenA.
     * @param _tokenB The address of tokenB.
     */
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        _grantRole(ADMIN_ROLE, msg.sender); // Grant the deployer the admin role
    }

    /**
     * @dev Adds liquidity to the contract.
     * @param amountA The amount of tokenA to add.
     * @param amountB The amount of tokenB to add.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyRole(ADMIN_ROLE) nonReentrant {
        try IERC20(tokenA).transferFrom(msg.sender, address(this), amountA) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        try IERC20(tokenB).transferFrom(msg.sender, address(this), amountB) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        emit AddLiquidity(msg.sender, amountA, amountB);
    }

    /**
     * @dev Removes liquidity from the contract.
     * @param amountA The amount of tokenA to remove.
     * @param amountB The amount of tokenB to remove.
     */
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyRole(ADMIN_ROLE) nonReentrant {
        try IERC20(tokenA).transfer(msg.sender, amountA) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        try IERC20(tokenB).transfer(msg.sender, amountB) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        emit RemoveLiquidity(msg.sender, amountA, amountB);
    }

    /**
     * @dev Swaps one token for another at a 1:1 ratio.
     * @param tokenIn The address of the token being swapped in.
     * @param amount The amount of tokens to swap.
     */
    function swap(address tokenIn, uint256 amount) external nonReentrant {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;
        require(IERC20(tokenOut).balanceOf(address(this)) >= amount, "Insufficient liquidity");

        try IERC20(tokenIn).transferFrom(msg.sender, address(this), amount) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        try IERC20(tokenOut).transfer(msg.sender, amount) {
        } catch Error(string memory reason) {
            revert(reason);
        }

        emit Swap(msg.sender, tokenIn, tokenOut, amount);
    }
}