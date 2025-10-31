 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("Mini Token", "MINI") ERC20Permit("MiniToken") {}


// Minting 1000000 tokens to the contract deployer on deployment
        _mint(msg.sender, 1000000 * (10 ** 18));

    }

// public mint function for only the owner to call
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
