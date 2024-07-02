// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IBattles} from "../src/interfaces/IBattles.sol";
import {IBattlesTicket} from "../src/interfaces/IBattlesTicket.sol";
import {TestBase} from "./TestBase.sol";

contract BattleTicketTest is TestBase {
    function setUp() public {
        _setUpBase();
    }

    function test_BattleTicket_Deployment() public view {
        assertEq(address(ticket.token()), address(token));
        assertEq(ticket.symbol(), "DBT");
    }

    function test_Settings() public {
        vm.startPrank(owner);
        ticket.setMinExpiry(uint64(magicNumber));
        assertEq(uint64(magicNumber), ticket.minExpiry());
    }

    function test_Ticket_Issuance() public {
        address[] memory recipients = new address[](2);
        uint256[] memory ticketPrices = new uint256[](2);
        uint64[] memory ticketExpirations = new uint64[](2);

        recipients[0] = user6;
        recipients[1] = user5;

        ticketPrices[0] = minAmount;
        ticketPrices[1] = minAmount;

        ticketExpirations[0] = 1 days;
        ticketExpirations[1] = 30 days;

        vm.startPrank(relayer);
        _test_Issuance(user5, recipients, ticketPrices, ticketExpirations);

        assertEq(ticket.totalSupply(), 2);
        assertEq(ticket.balanceOf(user6), 1);
        assertEq(token.balanceOf(address(ticket)), minAmount * 2);

        IBattlesTicket.Ticket memory ticket_ = ticket.getTicket(1);
        assertEq(ticket_.issuer, user5);
        assertEq(ticket_.amountLocked, minAmount);
        assertEq(ticket_.holder, user6);
        assertGt(ticket_.expirationDate, uint64(block.timestamp));
        vm.stopPrank();
    }

    function test_Ticket_Burner() public {
        address[] memory recipients = new address[](2);
        uint256[] memory ticketPrices = new uint256[](2);
        uint64[] memory ticketExpirations = new uint64[](2);

        recipients[0] = user6;
        recipients[1] = user5;

        ticketPrices[0] = minAmount;
        ticketPrices[1] = minAmount;

        ticketExpirations[0] = 1 days;
        ticketExpirations[1] = 1 days;

        vm.startPrank(relayer);

        _test_Issuance(user1, recipients, ticketPrices, ticketExpirations);

        assertEq(ticket.totalSupply(), 2);

        uint256[] memory tokenIds = new uint256[](1);

        tokenIds[0] = 1;

        vm.expectRevert("UNAUTHORIZED_CALLER");
        ticket.burnTickets(tokenIds, address(0));

        vm.stopPrank();

        skip(2 days);
        _test_Burner(user1, address(0), tokenIds);

        assertEq(ticket.totalSupply(), 1);
        assertEq(ticket.balanceOf(user6), 0);
        assertEq(token.balanceOf(address(ticket)), minAmount);
        assertEq(token.balanceOf(user1), minAmount * 2);
    }

    function test_MakePrediction_With_Tickets() public {
        address[] memory recipients = new address[](2);
        uint256[] memory ticketPrices = new uint256[](2);
        uint64[] memory ticketExpirations = new uint64[](2);

        recipients[0] = user6;
        recipients[1] = user5;

        ticketPrices[0] = minAmount;
        ticketPrices[1] = minAmount;

        ticketExpirations[0] = 1 days;
        ticketExpirations[1] = 30 days;

        vm.startPrank(relayer);

        // mint ticket
        _test_Issuance(user5, recipients, ticketPrices, ticketExpirations);

        // create battle
        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        IBattles.BattleOption option = IBattles.BattleOption.Option0;
        uint256 amount = minAmount;
        bool useNextWindow = true;

        _test_CreateBattle(user1, amount, manifest, option, useNextWindow);

        uint256[] memory ticketIds = new uint256[](1);
        ticketIds[0] = 2;

        uint256 initialBattleBal = token.balanceOf(address(battles));
        uint256 initialBattleTicketBal = token.balanceOf(address(ticket));

        _test_MakePrediction_With_Ticket(user5, 0, ticketIds, option);

        uint256 finalBattleBal = token.balanceOf(address(battles));
        uint256 finalBattleTicketBal = token.balanceOf(address(ticket));
        assertEq(finalBattleBal - initialBattleBal, initialBattleTicketBal - finalBattleTicketBal);

        assertEq(ticket.totalSupply(), 1);
        assertEq(ticket.balanceOf(user5), 0);
        assertEq(finalBattleTicketBal, minAmount);

        ticketIds[0] = 1;

        vm.stopPrank();

        vm.prank(user6);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        ticket.burnTickets(ticketIds, address(0));

        vm.prank(relayer);
        skip(ticketExpirations[1] + 10);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        battles.makePredictionWithTickets(user5, 2, ticketIds, option);
    }

    function test_Nontransferrability() public {
        vm.startPrank(user6);

        vm.expectRevert("Non-transferrable token");
        ticket.transferFrom(user6, user1, 1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 3;

        vm.expectRevert("Non-transferrable token");
        ticket.safeTransferFrom(user6, user1, 3);

        vm.expectRevert("Non-transferrable token");
        ticket.setApprovalForAll(user6, true);

        vm.expectRevert("Non-transferrable token");
        ticket.approve(user6, 1);
    }
}
