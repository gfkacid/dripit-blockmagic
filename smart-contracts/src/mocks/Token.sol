// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * this token is for testing the Lock Vault
 */
contract Token is ERC20 {
    uint8 decimal = 6; // USDC
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 1e11);
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return decimal;
    }
}
