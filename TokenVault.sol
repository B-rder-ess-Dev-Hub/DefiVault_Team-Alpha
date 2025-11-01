// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing the IERC20 interface to interact with any ERC-20 token, in our case; MiniToken.
// This tells our contract what functions (like transfer, transferFrom) the token has.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {
    
        // --- State Variables ---

        // This variable will hold the contract of the ERC-20 token we are staking.
                IERC20 public stakingToken;
        // Mapping to track each user's stake
                mapping(address => uint256) public stakes;
        // A counter for all tokens staked in this contract
                uint256 public totalStaked;

                // --- Reward Variables ---
                mapping(address => uint256) public rewards;
                uint256 public rewardRate;
                // To track when each user's rewards were last updated
                mapping(address => uint256) public lastUpdate;

                // --- Events ---
                event Staked(address indexed user, uint256 amount);
                event Unstaked(address indexed user, uint256 amount);
                // Event for claiming rewards
                event RewardsClaimed(address indexed user, uint256 amount);

                /**
                        * @dev We must tell the vault the address of the ERC-20 token it's supposed to accept.
                        * @param _tokenAddress The address of SimpleToken contract.
                        * @param _initialRewardRate The initial reward rate for staking = 100
                */
                                constructor(address _tokenAddress, uint256 _initialRewardRate) 
                                Ownable (msg.sender){
                                         stakingToken = IERC20(_tokenAddress);
                                         rewardRate = _initialRewardRate;
                                }

                // --- Internal Reward Function ---
                /**
                * @dev Internal helper functiom to cakculate snd accrue pending rewards for a user.
                * it updates their 'rewards' balance and resets their 'lastUpdate' to the current block.
                */
                function _updateRewards(address user) internal {
                        // We only calculate rewards if the user is actively staking.
                        if (stakes[user] > 0) {
                                uint256 pendingRewards = (block.number - lastUpdate[user]) * rewardRate;
                        // Adding the pending rewards to the accrued total
                        rewards[user] += pendingRewards;
                        }
                        // Updating the users 'last update' time to now.
                        lastUpdate[user] = block.number;
                }

                /*
                        * @dev Stakes a specific amount of tokens.
                        * Calculate and accrue pending rewards first.
                        * The user MUST have approved the vault to spend this amount first.
                        * @param amount The amount of tokens to stake.
                */
                        function stake(uint256 amount) public {
                        // 1. Check: Can't stake zero tokens.
                                require(amount > 0, "Cannot stake 0 tokens");

                        // 2. Calculate and bank any pending rewards before changing their stake balance.
                        _updateRewards(msg.sender);

                        // 3. transferFrom is used to pull the 'amount' of tokens from the 'msg.sender' (the user)
                        //    to 'address(this)' (this vault contract).
                        //    This will FAIL if the user did not approve the vault first.
                                bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
                                        require(success, "ERC20 transfer failed. Did you approve?");

                        // 4. Update Records: Now that the transfer succeeded, we update the user's stake and the total stake.
                                stakes[msg.sender] += amount;
                                        totalStaked += amount;

                        // 5. Emit the event
                        emit Staked(msg.sender, amount);
                                }

                /**
                        * @dev Unstakes a specific amount of tokens and returns the tokens from the vault back to the user.
                        * Now calculates and accrues pending rewards first.
                        * @param amount The amount of tokens to unstake.
                */
                                function unstake(uint256 amount) public {
                        // 1. Check: Can't unstake zero.
                                require(amount > 0, "Cannot unstake 0 tokens");

                        // 2. Check: Does the user have enough staked to withdraw?
                                require(stakes[msg.sender] >= amount, "Insufficient staked balance");

                        // 3. Calculate and bank any pending rewards before changing their stake balance.
                                _updateRewards(msg.sender);

                        // 4. Update Records: Update the state *before* the external call (transfer).
                        //    This prevents a security flaw called "re-entrancy".
                                stakes[msg.sender] -= amount;
                                totalStaked -= amount;

                        // 5. The Return: Send the tokens from the vault's balance back to the 'msg.sender' (the user).
                                bool success = stakingToken.transfer(msg.sender, amount);
                                require(success, "ERC20 transfer failed");

                        // 6. Emit the event
                                emit Unstaked(msg.sender, amount);
                                }

                // --- New Reward Functions ---
                /**
                        * @dev Function to view a user's total claimable rewards.
                        * It returns (what's already banked) + (what's pending since last update).
                */
                function calculateRewards(address user) public view returns (uint256) {
                // If the user has no stake, they can only have what's already in the bank.
                if (stakes[user] == 0) {
                        return rewards[user];
                }

                // To calculate pending rewards since the last updaate
                uint256 pendingRewards = (block.number - lastUpdate[user]) * rewardRate;
                // Return total claimaible(what's banked) + (what's pending)
                return rewards[user] + pendingRewards;
                }

                /**
                * @dev Function to claim all accrued rewards.
                * This will transfer the reward tokens from the vault to the user.
                */
                function claimRewards() public {
                        _updateRewards(msg.sender);

                // Get the total amount to claim
                uint256 amountToClaim = rewards[msg.sender];
                require(amountToClaim > 0, "No rewards to claim");

                // The vault must have enough tokens that are not staked to pay the reward.
                // Calculate the reward pool (Total Vault Balance) - (Total Staked)
                uint256 rewardPool = stakingToken.balanceOf(address(this)) - totalStaked;
                require(rewardPool >= amountToClaim, "Insufficient reward pool to pay out");

                // Updating the state first to prevent re-entrancy
                rewards[msg.sender] = 0;

                // Transferring the reward tokens to the user
                bool success = stakingToken.transfer(msg.sender, amountToClaim);
                require(success, "Reward transfer failed");

                // Emit the event
                emit RewardsClaimed(msg.sender, amountToClaim);
                }

/**
        * @dev Function to get a user's staked amount.
        * @param user The address of the user to check.
*/
                function getUserStakes(address user) public view returns (uint256) {
                        return stakes[user];
                        }

        // --- Emergency Withdraw Function ---
        /**
         * @dev Function to allow the owner to rescue the contract's funds.
         * @param tokenAddress The address of the token to withdraw
         * @param amount The amount of tokens to withdraw
         */
        function emergencyWithdrawStuckTokens(address tokenAddress, uint256 amount) public onlyOwner {
                require(amount > 0, "Amount must be greater than 0");
                IERC20 token = IERC20(tokenAddress);

                // --- Security Check ---
        // This check prevents the owner fro rug-pulling the funds that users have staked.
        // The owner can only withdraw the surplus (the reward pool).
        if (tokenAddress == address(stakingToken)) {
                uint256 rewardPool = token.balanceOf(address(this)) - totalStaked;
                require(amount <= rewardPool, "Cannot withdraw user's staked funds");
        }

        // If someone sends a random token, the owner can rescue it
        bool success = token.transfer(owner(), amount); 
        require(success, "Token transfer failed");
        }
}                                                                                                    