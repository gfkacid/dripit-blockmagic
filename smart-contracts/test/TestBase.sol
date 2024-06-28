// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Battles} from "../src/Battles.sol";
import {BattlesTicket} from "../src/BattlesTicket.sol";
import {IBattles} from "../src/interfaces/IBattles.sol";
import {IBattlesTicket} from "../src/interfaces/IBattlesTicket.sol";
import {Token} from "../src/mocks/Token.sol";

contract TestBase is Test {
    Battles public battles;
    BattlesTicket public ticket;
    Token public token;
    address public owner = address(100);
    address public relayer = address(99);
    address public treasury = address(98);
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);
    address public user4 = address(4);
    address public user5 = address(5);
    address public user6 = address(6);
    uint256 public minAmount;
    uint256 public magicNumber = 777;

    function _setUpBase() internal {
        vm.warp(1719187200 + 86400); // init monday timestamp + day
        vm.startPrank(owner);
        token = new Token();
        ticket = new BattlesTicket("dripit Battles Ticket", "DBT", "", address(token), owner, owner, 1 days);
        minAmount = 10 * (10 ** token.decimals());
        battles = new Battles();
        battles.initialize(owner, relayer, address(token), address(ticket), treasury, minAmount);
        ticket.grantRole(ticket.BATTLE_ROLE(), address(battles));
        token.transfer(user1, minAmount * 3);
        token.transfer(user2, minAmount * 3);
        token.transfer(user3, minAmount * 3);
        token.transfer(user4, minAmount * 3);
        token.transfer(user5, minAmount * 3);
        vm.stopPrank();
    }

    function _test_CreateBattle(
        address user,
        uint256 amount,
        IBattles.BattleManifest memory manifest,
        IBattles.BattleOption option,
        bool useNextWindow
    ) internal {
        if (token.allowance(user, address(battles)) < amount) {
            vm.startPrank(user);
            token.approve(address(battles), token.totalSupply());
            vm.stopPrank();
        }
        vm.startPrank(relayer);
        battles.createBattle(user, manifest, option, amount, useNextWindow);
    }

    function _test_MakePrediction(address user, uint256 id, IBattles.BattleOption option, uint256 amount) internal {
        if (token.allowance(user, address(battles)) < amount) {
            vm.startPrank(user);
            token.approve(address(battles), token.totalSupply());
            vm.stopPrank();
        }
        vm.startPrank(relayer);
        battles.makePrediction(user, id, option, amount);
    }

    function _test_resolveBattle(uint256 id) internal {
        battles.resolveBattle(id);
    }

    function _test_Issuance(
        address user,
        address[] memory recipients,
        uint256[] memory ticketPrices,
        uint64[] memory ticketExpirations
    ) internal {
        if (token.allowance(user, address(ticket)) < minAmount) {
            vm.startPrank(user);
            token.approve(address(ticket), token.totalSupply());
            vm.stopPrank();
        }
        vm.startPrank(relayer);
        ticket.mintTickets(user, recipients, ticketPrices, ticketExpirations);
    }

    function _test_Burner(address user, address who, uint256[] memory tokenIds) internal {
        vm.startPrank(user);
        ticket.burnTickets(tokenIds, who);
        vm.stopPrank();
    }

    function _test_MakePrediction_With_Ticket(
        address user,
        uint256 id,
        uint256[] memory ticketIds,
        IBattles.BattleOption option
    ) internal {
        battles.makePredictionWithTickets(user, id, ticketIds, option);
    }

    function _test_CreateBattle_With_Tickets(
        address user,
        uint256[] memory ticketIds,
        IBattles.BattleManifest memory manifest,
        IBattles.BattleOption option,
        bool useNextWindow
    ) internal {
        vm.startPrank(relayer);
        battles.createBattleWithTickets(user, manifest, option, ticketIds, useNextWindow);
    }

    function _predictionUtils(address user0, address user1_, bool same)
        internal
        returns (IBattles.BattleOption option, uint256 amount)
    {
        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        option = IBattles.BattleOption.Option0;
        bool useNextWindow = true;
        amount = minAmount;
        _test_CreateBattle(user0, amount, manifest, option, useNextWindow);
        _test_CreateBattle(user0, amount, manifest, option, !useNextWindow);

        uint256 id0 = 0;
        uint256 id1 = 1;

        option = same ? option : IBattles.BattleOption.Option1;

        _test_MakePrediction(user1_, id0, option, amount);
        _test_MakePrediction(user1_, id1, option, amount);
    }
}
