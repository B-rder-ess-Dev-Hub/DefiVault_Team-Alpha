// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {  /
    ERC20 public token;
    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public lastUpdateTime;

    uint256 public totalStaked;
    uint256 public  constant REWARD_RATE = 100; // reward per token staked is 100


    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);  // Initialize ERC20 at _tokenAddress
    }

    

    function stake(uint256 amount) external  updateReward(msg.sender) {
        require(amount > 0, "Amount must be > 0");
        token.transferFrom(msg.sender, address(this), amount);
        userStakes[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(userStakes[msg.sender] >= amount, "Not enough staked");
        userStakes[msg.sender] -= amount;  // Subtract, not overwrite
        totalStaked -= amount;             // Subtract, not overwrite
        token.transfer(msg.sender, amount);
    }

    //---Add claim function--//
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards(msg.sender);
        require(reward > 0, "No rewards Available");
        rewards[msg.sender] = 0;
        token.transfer(msg.sender, reward);
    }

    function getUserstake(address user) external view returns (uint256) {
        return userStakes[user];  //  Return the value
    }
    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate; // to assign new REWARD_RATE
