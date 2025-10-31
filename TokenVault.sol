// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {  /
    ERC20 public token;
    mapping(address => uint256) public userStakes;
    uint256 public totalStaked;

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);  // Initialize ERC20 at _tokenAddress
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        token.transferFrom(msg.sender, address(this), amount);
        userStakes[msg.sender] += amount;
        totalStaked += amount;
    }
