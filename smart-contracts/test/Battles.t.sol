// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Battles} from "../src/Battles.sol";
import {BattlesTicket} from "../src/BattlesTicket.sol";
import {IBattles} from "../src/interfaces/IBattles.sol";
import {IBattlesTicket} from "../src/interfaces/IBattlesTicket.sol";
import {Token} from "../src/mocks/Token.sol";

contract BattlesTest is Test {
    Battles public battles;
    BattlesTicket public ticket;
    Token public token;
    address public owner = address(100);
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);
    address public user4 = address(4);
    address public user5 = address(5);
    address public user6 = address(6);
    uint256 public minAmount;

    function setUp() public {
        vm.startPrank(owner);
        token = new Token();
        ticket = new BattlesTicket(
            "dripit Battles Ticket",
            "DBT",
            "",
            address(token),
            owner,
            owner,
            1 days
        );
        minAmount = 10 * (10 ** token.decimals());
        battles = new Battles(
            owner,
            address(token),
            address(ticket),
            minAmount
        );
        ticket.grantRole(ticket.BATTLE_ROLE(), address(battles));
        token.transfer(user1, minAmount * 3);
        token.transfer(user2, minAmount * 3);
        token.transfer(user3, minAmount * 3);
        token.transfer(user4, minAmount * 3);
        token.transfer(user5, minAmount * 3);
        vm.stopPrank();
    }
    function test_Deployment() public view {
        assertEq(address(battles.token()), address(token));
        assertEq((battles.minAmount()), minAmount);
    }
    function test_GenerateHash() public view {
        IBattles.BattleManifest memory manifestA = IBattles.BattleManifest(
            IBattles.BattleType.Track,
            "GOOD DAY",
            "BAD DAY"
        );

        (bytes32 hashA, ) = battles.generateHash(
            manifestA,
            uint64(block.timestamp)
        );
        IBattles.BattleManifest memory manifestB = IBattles.BattleManifest(
            IBattles.BattleType.Track,
            "BAD DAY",
            "GOOD DAY"
        );

        (bytes32 hashB, ) = battles.generateHash(
            manifestB,
            uint64(block.timestamp)
        );
        IBattles.BattleManifest memory manifestC = IBattles.BattleManifest(
            IBattles.BattleType.Artist,
            "2PAC",
            "BIGGY"
        );
        (bytes32 hashC, ) = battles.generateHash(
            manifestC,
            uint64(block.timestamp)
        );
        IBattles.BattleManifest memory manifestD = IBattles.BattleManifest(
            IBattles.BattleType.Artist,
            "BIGGY",
            "2PAC"
        );
        (bytes32 hashD, ) = battles.generateHash(
            manifestD,
            uint64(block.timestamp)
        );
        IBattles.BattleManifest memory manifestE = IBattles.BattleManifest(
            IBattles.BattleType.Track,
            "BIGGY",
            "2PAC"
        );
        (bytes32 hashE, ) = battles.generateHash(
            manifestE,
            uint64(block.timestamp)
        );
        assertEq(hashA, hashB);
        assertEq(hashC, hashD);
        assertNotEq(hashA, hashC);
        assertNotEq(hashE, hashC);
    }

    function test_Settings() public {
        vm.startPrank(owner);
        uint256 magicNumber = 777;
        ticket.setMinExpiry(uint64(magicNumber));
        assertEq(uint64(magicNumber), ticket.minExpiry());

        battles.setMinAmount(magicNumber);
        battles.setDuration(uint64(magicNumber));
        battles.setFutureLimit(uint64(magicNumber));
        battles.setMarketMakerIncentive(uint8(magicNumber));

        assertEq(battles.minAmount(), magicNumber);
        assertEq(battles.duration(), uint64(magicNumber));
        assertEq(battles.futureLimit(), uint64(magicNumber));
        assertEq(battles.marketMakerIncentive(), uint8(magicNumber));
    }
    function _test_CreateBattle_And_Fails() internal {
        uint256 id = battles.battleIds();
        assertEq(id, 0);
        vm.startPrank(user1);
        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(
            IBattles.BattleType.Artist,
            "BIGGY",
            "2PAC"
        );
        IBattles.BattleOption option = IBattles.BattleOption.Default;
        uint256 amount = minAmount - 1;
        uint64 secondsBeforeStart = battles.futureLimit();
        token.approve(address(battles), token.totalSupply());
        // should NOT accept an invalid option
        vm.expectRevert(bytes("Error: Wrong option"));
        battles.createBattle(
            address(user1),
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        // should NOT accept leess than minimum amount
        option = IBattles.BattleOption.Option0;
        vm.expectRevert(bytes("Error: Inssuficient amount input"));
        battles.createBattle(
            address(user1),
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        // should NOT allow creation too far in the future
        amount++;
        vm.expectRevert(bytes("Error: Too far in the future"));
        battles.createBattle(
            address(user1),
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        secondsBeforeStart /= 2;
        battles.createBattle(
            user1,
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        assertEq(battles.battleIds(), 1);
        IBattles.BattleData memory data = battles.getBattle(id);
        assertEq(data.creator, user1);
        assertEq(data.option0PrizePool + data.option1PrizePool, amount);
        assertEq(data.option0Count, 1);
        assertEq(data.option1Count, 0);
        assertEq(
            data.startTimestamp,
            uint64(block.timestamp) + secondsBeforeStart
        );
        assertEq(data.closeTimestamp, data.startTimestamp + battles.duration());
        assertEq(
            abi.encodePacked(data.winOption),
            abi.encodePacked(IBattles.BattleOption.Default)
        );

        vm.startPrank(user2);
        token.approve(address(battles), token.totalSupply());
        vm.expectRevert(bytes("Error: Manifest is already active"));
        battles.createBattle(
            user2,
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        // should NOT allow duplicate use of manifest
        secondsBeforeStart += 5000;
        vm.expectRevert(bytes("Error: Manifest is already active"));
        battles.createBattle(
            user2,
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        manifest = IBattles.BattleManifest(
            IBattles.BattleType.Track,
            "BIG POPPA",
            "HIT EM UP"
        );
        option = IBattles.BattleOption.Option1;
        battles.createBattle(
            user2,
            manifest,
            option,
            amount,
            secondsBeforeStart
        );
        assertEq(battles.battleIds(), 2);
    }
    function _test_MakePrediction() internal {
        _test_CreateBattle_And_Fails();
        // make prediction for battle ids 0 and 1
        uint256 id = 0;
        vm.startPrank(user3);
        IBattles.BattleOption option = IBattles.BattleOption.Default;
        uint256 amount = 200;
        token.approve(address(battles), token.totalSupply());
        uint64 secondsBeforeStart = (battles.futureLimit() / 2) + 5500;
        skip(secondsBeforeStart);
        // should NOT accept wrong options
        vm.expectRevert(bytes("Error: Wrong option"));
        battles.makePrediction(user3, id, option, amount);
        // should NOT accept wrong amount
        option = IBattles.BattleOption.Option1;
        vm.expectRevert(bytes("Error: Inssuficient amount input"));
        battles.makePrediction(user3, id, option, amount);
        amount = minAmount;
        battles.makePrediction(user3, id, option, amount);
        battles.makePrediction(user3, id + 1, option, amount);
        // should NOT accept double entries.
        vm.expectRevert(bytes("Update entries instead"));
        battles.makePrediction(user3, id + 1, option, amount);
        IBattles.BattleData memory data = battles.getBattle(id);
        assertEq(data.option0Count, 1);
        assertEq(data.option0Count, data.option1Count);
        assertEq(data.option0PrizePool + data.option1PrizePool, minAmount * 2);
        assertEq(data.option0Count, data.option1Count);

        vm.startPrank(user4);
        option = IBattles.BattleOption.Option0;
        amount = minAmount;
        token.approve(address(battles), token.totalSupply());
        battles.makePrediction(user4, id, option, amount);
        battles.makePrediction(user4, id + 1, option, amount);
        vm.stopPrank();
    }
    function _test_UpdateAmount() internal {
        _test_MakePrediction();
        vm.prank(user2);
        vm.expectRevert("Error: Make a prediction instead");
        battles.updateAmount(user2, 0, minAmount, false);
        uint256 amount = minAmount;
        vm.startPrank(user3);
        assertEq(token.balanceOf(user3), amount);
        IBattles.UserPrediction memory prediction = battles.getUserPrediction(
            user3,
            0
        );
        battles.updateAmount(user3, 0, amount, true);
        assertEq(token.balanceOf(user3), 0);
        IBattles.BattleData memory data = battles.getBattle(0);
        (uint256 prizePool, , ) = battles.getPrizePoolAndOdds(0);
        assertEq(prizePool, data.option0PrizePool + data.option1PrizePool);
        assertLt(
            prediction.amount,
            (battles.getUserPrediction(user3, 0)).amount
        );
        vm.expectRevert("Error: Insufficient balance");
        battles.updateAmount(user3, 0, amount * 3, false);
        battles.updateAmount(user3, 0, amount * 2, false);
        assertEq(token.balanceOf(user3), amount * 2);
        prediction = battles.getUserPrediction(user3, 0);
        assertEq(prediction.amount, 0);
        assertTrue(prediction.isClosed);
        battles.makePrediction(user3, 0, IBattles.BattleOption.Option1, amount);
        vm.stopPrank();
    }
    function _test_UpdateOption() internal {
        _test_UpdateAmount();
        vm.startPrank(user4);
        IBattles.BattleData memory data = battles.getBattle(0);
        IBattles.UserPrediction memory prediction = battles.getUserPrediction(
            user4,
            0
        );
        battles.updateOption(user4, 0);
        assertNotEq(data.option0Count, (battles.getBattle(0)).option0Count);
        assertNotEq(data.option1Count, (battles.getBattle(0)).option1Count);
        assertNotEq(
            abi.encodePacked(prediction.option),
            abi.encodePacked((battles.getUserPrediction(user4, 0)).option)
        );
        // increment time to start time
        uint64 timeInSeconds = battles.futureLimit() / 2;
        skip(timeInSeconds);
        // should NOT allow if is close
        vm.expectRevert(bytes("Error: Entry is not open"));
        battles.makePrediction(
            user3,
            0,
            IBattles.BattleOption.Option1,
            minAmount
        );
        vm.expectRevert("Error: Entry is not open");
        battles.updateAmount(user2, 0, minAmount, false);
        vm.expectRevert("Error: Entry is not open");
        battles.updateOption(user4, 0);
        vm.stopPrank();
    }
    function _test_resolveBattle() internal {
        _test_UpdateOption();
        vm.prank(user1);
        vm.expectRevert();
        battles.resolveBattle(0);
        vm.startPrank(owner);
        vm.expectRevert("Error: Invalid operation");
        battles.resolveBattle(33);
        battles.resolveBattle(0);
        battles.resolveBattle(1);
        IBattles.BattleData memory data0 = battles.getBattle(0);
        IBattles.BattleData memory data1 = battles.getBattle(1);
        assertNotEq(data0.aPIRequestId, 0);
        assertNotEq(data1.aPIRequestId, 0);
        assertNotEq(
            abi.encodePacked(data0.winOption),
            abi.encodePacked(IBattles.BattleOption.Default)
        );
        assertNotEq(
            abi.encodePacked(data1.winOption),
            abi.encodePacked(IBattles.BattleOption.Default)
        );
    }

    function _test_Payouts() internal {
        _test_resolveBattle();

        uint256 limit = 10000; // -> 100%
        uint256 remaining = limit - battles.marketMakerIncentive();
        (uint256 prizePool, , ) = battles.getPrizePoolAndOdds(0);
        console.log("prizePool: ", prizePool);

        uint256 magNum = (prizePool * remaining) / (limit);
        assertEq(battles.getMarketMakerIncentive(0) + magNum, prizePool);

        uint256 creatorBalInit0 = token.balanceOf(user1);
        uint256 creatorBalInit1 = token.balanceOf(user2);
        uint256 creatorIncentive0 = battles.getMarketMakerIncentive(0);
        uint256 creatorIncentive1 = battles.getMarketMakerIncentive(1);
        uint256[] memory battleIds = new uint256[](2);
        battleIds[0] = 0;
        battleIds[1] = 1;
        battles.claimMarketMakerIncentives(battleIds);

        uint256 creatorBalFinal0 = token.balanceOf(user1);
        uint256 creatorBalFinal1 = token.balanceOf(user2);
        uint256 creatorBalInit3 = token.balanceOf(user3);
        uint256 creatorBalInit4 = token.balanceOf(user4);

        assertEq(creatorBalInit0 + creatorIncentive0, creatorBalFinal0);
        assertEq(creatorBalInit1 + creatorIncentive1, creatorBalFinal1);

        vm.expectRevert("Error: Invalid operation");
        battles.claimMarketMakerIncentives(battleIds);

        battleIds[0] = 3;

        vm.expectRevert("Error: Invalid operation");
        battles.claimMarketMakerIncentives(battleIds);

        IBattles.BattleData memory data0 = battles.getBattle(0);
        IBattles.BattleData memory data1 = battles.getBattle(1);

        uint256 payoutId0User3 = battles.getPayout(user3, 0);
        uint256 payoutId1User3 = battles.getPayout(user3, 1);

        uint256 payoutId0User4 = battles.getPayout(user4, 0);
        uint256 payoutId1User4 = battles.getPayout(user4, 1);

        uint256 payoutId0User1 = battles.getPayout(user1, 0);
        uint256 payoutId1User1 = battles.getPayout(user1, 1);

        uint256 payoutId0User2 = battles.getPayout(user2, 0);
        uint256 payoutId1User2 = battles.getPayout(user2, 1);

        assert(data0.winOption != IBattles.BattleOption.Default);

        IBattles.UserPrediction memory predictionId0User1 = battles
            .getUserPrediction(user1, 0);
        IBattles.UserPrediction memory predictionId0User3 = battles
            .getUserPrediction(user3, 0);

        console.log("predictionId0User1: ", predictionId0User1.amount);
        console.log("predictionId0User3: ", predictionId0User3.amount);

        console.log("data0 pool0: ", data0.option0PrizePool);
        console.log("data0 pool1: ", data0.option1PrizePool);
        console.log("data0 option0Count: ", data0.option0Count);
        console.log("data0 option1Count: ", data0.option1Count);

        uint256[] memory battleId = new uint256[](1);

        battleId[0] = 0;
        battles.claimWin(user1, battleId);

        console.log("payoutId0User1: ", payoutId0User1);
        console.log("payoutId0User2: ", payoutId0User2);
        console.log("payoutId0User3: ", payoutId0User3);
        console.log("payoutId0User4: ", payoutId0User4);
        console.log("total - fee: ", prizePool - creatorIncentive0);

        if (data0.winOption == IBattles.BattleOption.Option0) {
            assertEq(payoutId0User3, payoutId0User4);
            assertEq(payoutId0User4, 0);
            assertEq(payoutId0User1, (prizePool - creatorIncentive0));
            assertEq(token.balanceOf(user1), creatorBalFinal0 + payoutId0User1);
        } else if (data0.winOption == IBattles.BattleOption.Option1) {
            assertEq(payoutId0User3, payoutId0User4);
            assertEq(payoutId0User3, (prizePool - creatorIncentive0) / 2);
            assertEq(payoutId0User1, 0);
            assertEq(token.balanceOf(user3), creatorBalInit3 + payoutId0User3);
        }

        creatorBalInit3 = token.balanceOf(user3);
        creatorBalInit4 = token.balanceOf(user4);
        battleId[0] = 1;
        battles.claimWin(user4, battleId);

        console.log("payoutId1User1: ", payoutId1User1);
        console.log("payoutId1User2: ", payoutId1User2);
        console.log("payoutId1User3: ", payoutId1User3);
        console.log("payoutId1User4: ", payoutId1User4);
        console.log("total - fee: ", prizePool - creatorIncentive1);

        if (data1.winOption == IBattles.BattleOption.Option0) {
            assertEq(payoutId1User3, payoutId1User2);
            assertEq(payoutId1User3, 0);
            assertEq(payoutId1User4, (prizePool - creatorIncentive1));
            assertEq(token.balanceOf(user4), creatorBalInit4 + payoutId1User4);
        } else if (data1.winOption == IBattles.BattleOption.Option1) {
            assertEq(payoutId1User3, payoutId1User2);
            assertEq(payoutId1User4, 0);
            assertEq(payoutId1User3, (prizePool - creatorIncentive1) / 2);
            assertEq(token.balanceOf(user3), creatorBalInit3 + payoutId1User3);
        }
        vm.stopPrank();
    }

    function test_Tickets() public {
        _test_Payouts();
        vm.startPrank(user5);
        token.approve(address(ticket), token.totalSupply());
        console.log("allowance: ", token.allowance(user5, address(ticket)));
        address user7 = address(7);
        address[] memory recipients = new address[](2);
        uint256[] memory ticketPrices = new uint256[](2);
        uint64[] memory ticketExpirations = new uint64[](2);

        recipients[0] = address(0);
        recipients[1] = user7;

        ticketPrices[0] = 0;
        ticketPrices[1] = minAmount;

        ticketExpirations[0] = 1 hours;
        ticketExpirations[1] = 30 days;
        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("Null address for recipient");
        ticket.mintTickets(user5, recipients, ticketPrices, ticketExpirations);
        recipients[0] = user6;

        vm.expectRevert("Null value for ticketPrice");
        ticket.mintTickets(user5, recipients, ticketPrices, ticketExpirations);
        ticketPrices[0] = minAmount;

        vm.expectRevert("Min expiry for ticketExpiration not met");
        ticket.mintTickets(user5, recipients, ticketPrices, ticketExpirations);
        ticketExpirations[0] = 1 days;

        ticket.mintTickets(user5, recipients, ticketPrices, ticketExpirations);
        assertEq(ticket.totalSupply(), 2);
        assertEq(ticket.balanceOf(user6, 1), 1);
        assertEq(token.balanceOf(address(ticket)), minAmount * 2);

        IBattlesTicket.Ticket memory ticket_ = ticket.getTicket(1);
        assertEq(ticket_.issuer, user5);
        assertEq(ticket_.amountLocked, minAmount);
        assertEq(ticket_.holder, user6);
        assertGt(ticket_.expirationDate, uint64(block.timestamp));

        uint256[] memory ids = new uint256[](1);
        ids[0] = 2;

        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(
            IBattles.BattleType.Artist,
            "BIGGY",
            "NAS"
        );
        battles.createBattle(
            user2,
            manifest,
            IBattles.BattleOption.Option0,
            minAmount,
            0
        );

        skip(100);

        battles.makePredictionWithTickets(
            user7,
            2,
            IBattles.BattleOption.Option1,
            ids
        );
        assertEq(ticket.totalSupply(), 1);
        assertEq(ticket.balanceOf(user7, 2), 0);
        assertEq(token.balanceOf(address(ticket)), minAmount);

        ids[0] = 1;
        vm.stopPrank();
        vm.startPrank(user5);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        ticket.burnTickets(ids, address(0));

        skip(ticketExpirations[1] + 10);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        battles.makePredictionWithTickets(
            user6,
            2,
            IBattles.BattleOption.Option1,
            ids
        );

        ticket.burnTickets(ids, address(0));
        assertEq(ticket.totalSupply(), 0);
        assertEq(ticket.balanceOf(user6, 1), 0);
        assertEq(token.balanceOf(address(ticket)), 0);
        assertEq(token.balanceOf(user5), minAmount * 2);

        ticket.mintTickets(user5, recipients, ticketPrices, ticketExpirations);
        assertEq(ticket.totalSupply(), 2);
        assertEq(ticket.balanceOf(user6, 3), 1);
        assertEq(ticket.balanceOf(user7, 4), 1);

        vm.stopPrank();

        vm.startPrank(user6);

        vm.expectRevert("Non-transferrable token");
        ticket.safeTransferFrom(user6, user1, 3, 1, "");

        ids[0] = 3;

        vm.expectRevert("Non-transferrable token");
        ticket.safeBatchTransferFrom(user6, user1, ids, ids, "");

        vm.expectRevert("Non-transferrable token");
        ticket.setApprovalForAll(user6, true);
    }
}
