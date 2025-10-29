// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Defining the contract
contract MiniToken is ERC20, Ownable {
    constructor()
        ERC20("MiniToken", "MINI")
        Ownable(msg.sender)
    {
        
        // Minting 1000000 tokens to the contract deployer on deployment
        _mint(msg.sender, 1000000 * (10 ** 18));

    }

// public mint function for only the owner to call
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
