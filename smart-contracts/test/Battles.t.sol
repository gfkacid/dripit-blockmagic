// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/Battles.sol";
import {Token} from "../src/mocks/Token.sol";

contract BattlesTest is Test {
    Battles public battles;
    Token public token;
    address public owner = address(100);
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);
    address public user4 = address(4);
    uint256 public minAmount;

    function setUp() public {
        vm.startPrank(owner);
        token = new Token();
        minAmount = 10 * (10 ** token.decimals());
        battles = new Battles(owner, address(token), minAmount);
        token.transfer(user1, minAmount * 3);
        token.transfer(user2, minAmount * 3);
        token.transfer(user3, minAmount * 3);
        token.transfer(user4, minAmount * 3);
        vm.stopPrank();
    }
    function test_Deployment() public view {
        assertEq(address(battles.token()), address(token));
        assertEq((battles.minAmount()), minAmount);
    }
    function test_GenerateHash() public view {
        BattleManifest memory manifestA = BattleManifest(
            BattleType.Track,
            "GOOD DAY",
            "BAD DAY"
        );

        (bytes32 hashA, ) = battles.generateHash(
            manifestA,
            uint64(block.timestamp)
        );
        BattleManifest memory manifestB = BattleManifest(
            BattleType.Track,
            "BAD DAY",
            "GOOD DAY"
        );

        (bytes32 hashB, ) = battles.generateHash(
            manifestB,
            uint64(block.timestamp)
        );
        BattleManifest memory manifestC = BattleManifest(
            BattleType.Artist,
            "2PAC",
            "BIGGY"
        );
        (bytes32 hashC, ) = battles.generateHash(
            manifestC,
            uint64(block.timestamp)
        );
        BattleManifest memory manifestD = BattleManifest(
            BattleType.Artist,
            "BIGGY",
            "2PAC"
        );
        (bytes32 hashD, ) = battles.generateHash(
            manifestD,
            uint64(block.timestamp)
        );
        BattleManifest memory manifestE = BattleManifest(
            BattleType.Track,
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
    function _test_CreateBattle_And_Fails() internal {
        uint256 id = battles.battleIds();
        assertEq(id, 0);
        vm.startPrank(user1);
        BattleManifest memory manifest = BattleManifest(
            BattleType.Artist,
            "BIGGY",
            "2PAC"
        );
        BattleOption option = BattleOption.Default;
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
        option = BattleOption.Option0;
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
        BattleData memory data = battles.getBattle(id);
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
            abi.encodePacked(BattleOption.Default)
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
        manifest = BattleManifest(BattleType.Track, "BIG POPPA", "HIT EM UP");
        option = BattleOption.Option1;
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
        BattleOption option = BattleOption.Default;
        uint256 amount = 200;
        token.approve(address(battles), token.totalSupply());
        // should NOT accept wrong options
        vm.expectRevert(bytes("Error: Wrong option"));
        battles.makePrediction(user3, id, option, amount);
        // should NOT accept wrong amount
        option = BattleOption.Option1;
        vm.expectRevert(bytes("Error: Inssuficient amount input"));
        battles.makePrediction(user3, id, option, amount);
        amount = minAmount;
        battles.makePrediction(user3, id, option, amount);
        battles.makePrediction(user3, id + 1, option, amount);
        // should NOT accept double entries.
        vm.expectRevert(bytes("Update entries instead"));
        battles.makePrediction(user3, id + 1, option, amount);
        BattleData memory data = battles.getBattle(id);
        assertEq(data.option0Count, 1);
        assertEq(data.option0Count, data.option1Count);
        assertEq(data.option0PrizePool + data.option1PrizePool, minAmount * 2);
        assertEq(data.option0Count, data.option1Count);

        vm.startPrank(user4);
        option = BattleOption.Option0;
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
        UserPrediction memory prediction = battles.getUserPrediction(user3, 0);
        battles.updateAmount(user3, 0, amount, true);
        assertEq(token.balanceOf(user3), 0);
        BattleData memory data = battles.getBattle(0);
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
        battles.makePrediction(user3, 0, BattleOption.Option1, amount);
        vm.stopPrank();
    }
    function _test_UpdateOption() internal {
        _test_UpdateAmount();
        vm.startPrank(user4);
        BattleData memory data = battles.getBattle(0);
        UserPrediction memory prediction = battles.getUserPrediction(user4, 0);
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
        battles.makePrediction(user3, 0, BattleOption.Option1, minAmount);
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
        vm.expectRevert("Error: Invalid operation");
        battles.resolveBattle(0);
        // increment time to close time
        uint64 timeInSeconds = battles.duration() + 5000;
        skip(timeInSeconds);
        battles.resolveBattle(0);
        battles.resolveBattle(1);
        BattleData memory data0 = battles.getBattle(0);
        BattleData memory data1 = battles.getBattle(1);
        assertNotEq(data0.aPIRequestId, 0);
        assertNotEq(data1.aPIRequestId, 0);
        assertNotEq(
            abi.encodePacked(data0.winOption),
            abi.encodePacked(BattleOption.Default)
        );
        assertNotEq(
            abi.encodePacked(data1.winOption),
            abi.encodePacked(BattleOption.Default)
        );
    }

    function test_payouts() public {
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

        assertEq(creatorBalInit0 + creatorIncentive0, creatorBalFinal0);
        assertEq(creatorBalInit1 + creatorIncentive1, creatorBalFinal1);

        vm.expectRevert("Error: Invalid operation");
        battles.claimMarketMakerIncentives(battleIds);

        battleIds[0] = 3;

        vm.expectRevert("Error: Invalid operation");
        battles.claimMarketMakerIncentives(battleIds);

        BattleData memory data0 = battles.getBattle(0);
        BattleData memory data1 = battles.getBattle(1);

        uint256 payoutId0User3 = battles.getPayout(user3, 0);
        uint256 payoutId1User3 = battles.getPayout(user3, 1);

        uint256 payoutId0User4 = battles.getPayout(user4, 0);
        uint256 payoutId1User4 = battles.getPayout(user4, 1);

        uint256 payoutId0User1 = battles.getPayout(user1, 0);
        uint256 payoutId1User1 = battles.getPayout(user1, 1);

        uint256 payoutId0User2 = battles.getPayout(user2, 0);
        uint256 payoutId1User2 = battles.getPayout(user2, 1);

        assert(data0.winOption != BattleOption.Default);

        UserPrediction memory predictionId0User1 = battles.getUserPrediction(
            user1,
            0
        );
        UserPrediction memory predictionId0User3 = battles.getUserPrediction(
            user3,
            0
        );

        console.log("predictionId0User1: ", predictionId0User1.amount);
        console.log("predictionId0User3: ", predictionId0User3.amount);

        console.log("data0 pool0: ", data0.option0PrizePool);
        console.log("data0 pool1: ", data0.option1PrizePool);
        console.log("data0 option0Count: ", data0.option0Count);
        console.log("data0 option1Count: ", data0.option1Count);

        if (data0.winOption == BattleOption.Option0) {
            console.log("payoutId0User1: ", payoutId0User1);
            console.log("payoutId0User2: ", payoutId0User2);
            console.log("payoutId0User3: ", payoutId0User3);
            console.log("payoutId0User4: ", payoutId0User4);
            console.log("total - fee: ", prizePool - creatorIncentive0);

            assertEq(payoutId0User3, payoutId0User4);
            assertEq(payoutId0User4, 0);
            assertEq(payoutId0User1, (prizePool - creatorIncentive0));
        } else if (data0.winOption == BattleOption.Option1) {
            assertEq(payoutId0User3, payoutId0User4);
            assertEq(payoutId0User3, (prizePool - creatorIncentive0) / 2);
            assertEq(payoutId0User1, 0);
        }

        if (data1.winOption == BattleOption.Option0) {
            assertEq(payoutId1User3, payoutId1User2);
            assertEq(payoutId1User3, 0);
            assertEq(payoutId1User4, (prizePool - creatorIncentive1));
        } else if (data1.winOption == BattleOption.Option1) {
            assertEq(payoutId1User3, payoutId1User2);
            assertEq(payoutId1User4, 0);
            assertEq(payoutId1User4, (prizePool - creatorIncentive1) / 2);
        }
    }
}
