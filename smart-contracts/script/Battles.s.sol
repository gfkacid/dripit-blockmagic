// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Battles} from "../src/Battles.sol";
import {Token} from "../src/mocks/Token.sol";

contract MyScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Token token = new Token();
        console.log("Token deployed to : ", address(token));

        address initialOwner = vm.addr(privateKey);
        uint256 minAmount = 50 * (10 ** token.decimals()); // 50 USD

        Battles battles = new Battles(initialOwner, address(token), minAmount);
        console.log("Battles deployed to : ", address(battles));

        vm.stopBroadcast();
    }
}
