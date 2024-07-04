// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Battles} from "../src/Battles.sol";
import {Token} from "../src/mocks/Token.sol";
import {BattlesTicket} from "../src/BattlesTicket.sol";

contract MyScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        address usdcTestnet = 0x5425890298aed601595a70AB815c96711a31Bc65;
        Token token = Token(usdcTestnet);
        console.log("Token conected in : ", address(token));
        address initialOwner = vm.addr(privateKey);
        address owner = initialOwner;
        address relayer = initialOwner;
        address treasury = initialOwner;
        address secondOwner = 0xC57b1f6d9b66d528aF1cD2D0a7a2FFA389CD3A10;

        BattlesTicket ticket =
            new BattlesTicket("dripit", "DPT", "", address(token), initialOwner, initialOwner, 1 days);

        console.log("BattleTicket conected to : ", address(ticket));

        uint256 minAmount = 50 * (10 ** token.decimals()); // 50 USD

        Battles battles = new Battles();
        battles.initialize(owner, relayer, address(token), address(ticket), treasury, minAmount);
        console.log("Battles deployed to : ", address(battles));

        // grant role to battle contract
        ticket.grantRole(ticket.BATTLE_ROLE(), address(battles));

        battles.grantRole(battles.RELAYER_ROLE(), secondOwner);
        battles.grantRole(battles.ADMIN_ROLE(), secondOwner);
        vm.stopBroadcast();
    }
}
