// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IBattles} from "../src/interfaces/IBattles.sol";
import {IBattlesTicket} from "../src/interfaces/IBattlesTicket.sol";
import {TestBase, console} from "./TestBase.sol";

contract BattlesTest is TestBase {
    function setUp() public {
        _setUpBase();
    }

    function test_Battles_Deployment() public view {
        assertEq(address(battles.token()), address(token));
        assertEq((battles.minAmount()), minAmount);
    }

    function test_GenerateHash() public view {
        IBattles.BattleManifest memory manifestA =
            IBattles.BattleManifest(IBattles.BattleType.Track, "GOODDAY", "BADDAY");
        (bytes32 hashA,) = battles.generateHash(manifestA, uint64(block.timestamp));

        IBattles.BattleManifest memory manifestB =
            IBattles.BattleManifest(IBattles.BattleType.Track, "BADDAY", "GOODDAY");
        (bytes32 hashB,) = battles.generateHash(manifestB, uint64(block.timestamp));

        IBattles.BattleManifest memory manifestC = IBattles.BattleManifest(IBattles.BattleType.Artist, "2PAC", "BIGGY");
        (bytes32 hashC,) = battles.generateHash(manifestC, uint64(block.timestamp));

        IBattles.BattleManifest memory manifestD = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        (bytes32 hashD,) = battles.generateHash(manifestD, uint64(block.timestamp));

        IBattles.BattleManifest memory manifestE = IBattles.BattleManifest(IBattles.BattleType.Track, "BIGGY", "2PAC");
        (bytes32 hashE,) = battles.generateHash(manifestE, uint64(block.timestamp));

        assertEq(hashA, hashB);
        assertEq(hashC, hashD);
        assertNotEq(hashA, hashC);
        assertNotEq(hashE, hashC);
    }

    function test_Settings() public {
        vm.startPrank(owner);

        battles.setMinAmount(magicNumber);
        battles.setPlatformFee(uint8(magicNumber));
        battles.setMarketMakerIncentive(uint8(magicNumber));
        battles.setTreasury(address(98));
        IBattles.BattleTimeline memory _timeline =
            IBattles.BattleTimeline(uint64(magicNumber), uint64(magicNumber), uint64(magicNumber));
        battles.setTimeline(_timeline);

        assertEq(battles.minAmount(), magicNumber);
        assertEq(battles.marketMakerIncentive(), uint8(magicNumber));
        assertEq(battles.platformFee(), uint8(magicNumber));
        assertEq(battles.treasury(), address(98));
        (,, uint64 maxIntervals) = battles.timeline();
        assertEq(maxIntervals, magicNumber);
    }

    function test_CreateBattle() public {
        uint256 id = battles.battleIds();
        assertEq(id, 0);
        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        IBattles.BattleOption option = IBattles.BattleOption.Default;
        uint256 amount = minAmount - 1;
        bool useNextWindow = true;

        vm.startPrank(user1);
        token.approve(address(battles), token.totalSupply());
        vm.stopPrank();

        vm.startPrank(relayer);
        // should NOT accept an invalid option
        vm.expectRevert(bytes("Error: Wrong option"));
        battles.createBattle(user1, manifest, option, amount, useNextWindow);
        // should NOT accept less than minimum amount
        option = IBattles.BattleOption.Option0;
        vm.expectRevert(bytes("Error: Inssuficient amount input"));
        battles.createBattle(user1, manifest, option, amount, useNextWindow);
        // should NOT allow creation too far in the future
        amount++;

        (, uint64 interval,) = battles.timeline();
        (uint64 nextMondayTimestamp,) = battles.mondayUtil();

        _test_CreateBattle(user1, amount, manifest, option, useNextWindow);
        assertEq(battles.battleIds(), 1);

        IBattles.BattleData memory data = battles.getBattle(id);
        assertEq(data.creator, user1);
        assertEq(data.option0PrizePool + data.option1PrizePool, amount);
        assertEq(data.option0Count, 1);
        assertEq(data.option1Count, 0);
        assertEq(data.startTimestamp, nextMondayTimestamp);
        assertEq(data.closeTimestamp, data.startTimestamp + interval);
        assertEq(abi.encodePacked(data.winOption), abi.encodePacked(IBattles.BattleOption.Default));

        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(battles), token.totalSupply());
        vm.stopPrank();

        vm.startPrank(relayer);

        // should NOT allow duplicate use of manifest
        vm.expectRevert(bytes("Error: Manifest is already active"));
        battles.createBattle(user2, manifest, option, amount, useNextWindow);

        manifest = IBattles.BattleManifest(IBattles.BattleType.Track, "BIG POPPA", "HIT EM UP");
        option = IBattles.BattleOption.Option1;

        useNextWindow = false;
        _test_CreateBattle(user2, amount, manifest, option, useNextWindow);
        assertEq(battles.battleIds(), 2);

        vm.stopPrank();
    }

    function test_CreateBattle_With_Tickets() public {
        address[] memory recipients = new address[](2);
        uint256[] memory ticketPrices = new uint256[](2);
        uint64[] memory ticketExpirations = new uint64[](2);

        recipients[0] = user2;
        recipients[1] = user2;

        ticketPrices[0] = minAmount;
        ticketPrices[1] = minAmount;

        ticketExpirations[0] = 100 days;
        ticketExpirations[1] = 100 days;

        vm.startPrank(relayer);

        _test_Issuance(user1, recipients, ticketPrices, ticketExpirations);

        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        IBattles.BattleOption option = IBattles.BattleOption.Option0;
        bool useNextWindow = true;

        uint256[] memory ticketIds = new uint256[](2);
        ticketIds[0] = 1;
        ticketIds[1] = 2;

        _test_CreateBattle_With_Tickets(user2, ticketIds, manifest, option, useNextWindow);
        assertEq(battles.battleIds(), 1);

        IBattles.BattleData memory data = battles.getBattle(0);
        assertEq(data.creator, user2);
        assertEq(data.option0PrizePool + data.option1PrizePool, 2 * minAmount);
        assertEq((battles.getUserPrediction(user2, 0)).amount, 2 * minAmount);

        vm.stopPrank();
    }

    function test_MakePrediction() public {
        vm.prank(relayer);
        (IBattles.BattleOption option, uint256 amount) = _predictionUtils(user1, user3, true);

        uint256 id0 = 0;
        uint256 id1 = 1;

        // should NOT accept double entries.
        vm.expectRevert(bytes("Update entries instead"));
        battles.makePrediction(user3, id0, option, amount);

        IBattles.BattleData memory data = battles.getBattle(id0);
        assertEq(data.option0Count, 2);
        assertEq(data.option0PrizePool, minAmount * 2);
        assertEq(data.option1Count, 0);

        option = IBattles.BattleOption.Option0;

        _test_MakePrediction(user4, id0, option, amount);
        _test_MakePrediction(user4, id1, option, amount);

        vm.stopPrank();
    }

    function test_UpdateAmount() public {
        vm.startPrank(relayer);
        (, uint256 amount) = _predictionUtils(user1, user3, true);

        vm.expectRevert("Error: Make a prediction instead");
        battles.updateAmount(user2, 0, minAmount);

        assertEq(token.balanceOf(user3), amount);

        IBattles.UserPrediction memory prediction = battles.getUserPrediction(user3, 0);
        battles.updateAmount(user3, 0, amount);
        assertEq(token.balanceOf(user3), 0);

        IBattles.BattleData memory data = battles.getBattle(0);
        (uint256 prizePool,,) = battles.getPrizePoolAndOdds(0);
        assertEq(prizePool, data.option0PrizePool + data.option1PrizePool);
        assertLt(prediction.amount, (battles.getUserPrediction(user3, 0)).amount);

        // increment time to start time
        skip(30 days);

        vm.expectRevert("Error: Entry is not open");
        battles.updateAmount(user1, 0, minAmount);

        vm.stopPrank();
    }

    function test_ResolveBattle() public {
        vm.startPrank(relayer);
        _predictionUtils(user1, user3, false);

        vm.expectRevert();
        battles.resolveBattle(0);

        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert("Error: Empty pool");
        battles.resolveBattle(33);

        vm.expectRevert("Error: Not yet");
        battles.resolveBattle(0);

        skip(30 days);

        _test_resolveBattle(0);
        _test_resolveBattle(1);

        vm.expectRevert("Error: Battle closed already");
        battles.resolveBattle(0);

        IBattles.BattleData memory data0 = battles.getBattle(0);
        IBattles.BattleData memory data1 = battles.getBattle(1);

        assert(data0.winOption != IBattles.BattleOption.Default);
        assert(!data0.isRefundable);

        assertNotEq(data0.aPIRequestId, 0);
        assertNotEq(data1.aPIRequestId, 0);

        assertNotEq(abi.encodePacked(data0.winOption), abi.encodePacked(IBattles.BattleOption.Default));
        assertNotEq(abi.encodePacked(data1.winOption), abi.encodePacked(IBattles.BattleOption.Default));

        vm.stopPrank();
    }

    function test_Payouts() public {
        uint256 limit = 10000; // -> 100%
        uint256 remaining = limit - (battles.marketMakerIncentive() + battles.platformFee());

        vm.startPrank(relayer);

        _predictionUtils(user1, user2, true);
        _test_MakePrediction(user3, 0, IBattles.BattleOption.Option1, minAmount);
        _test_MakePrediction(user4, 0, IBattles.BattleOption.Option1, minAmount);
        _test_MakePrediction(user3, 1, IBattles.BattleOption.Option1, minAmount);
        _test_MakePrediction(user4, 1, IBattles.BattleOption.Option1, minAmount);

        (uint256 prizePool,,) = battles.getPrizePoolAndOdds(0);

        uint256 magNum = (prizePool * remaining) / (limit);
        assertEq(battles.getMarketMakerIncentive(0) + magNum, prizePool);

        uint256 creatorBalInit = token.balanceOf(user1);

        uint256 creatorIncentive0 = battles.getMarketMakerIncentive(0);
        uint256 creatorIncentive1 = battles.getMarketMakerIncentive(1);

        uint256[] memory battleIds = new uint256[](2);
        battleIds[0] = 0;
        battleIds[1] = 1;

        vm.expectRevert("Error: Unresolved battle");
        battles.claimMarketMakerIncentives(battleIds);

        skip(30 days);
        vm.stopPrank();

        vm.startPrank(owner);

        _test_resolveBattle(0);
        _test_resolveBattle(1);

        vm.stopPrank();

        vm.startPrank(relayer);

        battles.claimMarketMakerIncentives(battleIds);

        uint256 creatorBalFinal = token.balanceOf(user1);

        assertEq(creatorBalInit + creatorIncentive0 + creatorIncentive1, creatorBalFinal);

        vm.expectRevert("Error: Already claimed");
        battles.claimMarketMakerIncentives(battleIds);

        IBattles.BattleData memory data0 = battles.getBattle(0);
        IBattles.BattleData memory data1 = battles.getBattle(1);

        uint256 payoutId0User1 = battles.getPayout(user1, 0);
        uint256 payoutId1User1 = battles.getPayout(user1, 1);
        uint256 payoutId0User2 = battles.getPayout(user2, 0);
        uint256 payoutId1User2 = battles.getPayout(user2, 1);
        uint256 payoutId0User3 = battles.getPayout(user3, 0);
        uint256 payoutId1User3 = battles.getPayout(user3, 1);
        uint256 payoutId0User4 = battles.getPayout(user4, 0);
        uint256 payoutId1User4 = battles.getPayout(user4, 1);

        uint256[] memory battleId = new uint256[](1);
        battleId[0] = 0;

        if (data0.winOption == IBattles.BattleOption.Option0) {
            battles.claimWin(user1, battleId);
            assertEq(payoutId0User1, payoutId0User2);
            assertEq(payoutId0User4, 0);
            assertEq(payoutId0User1, ((prizePool - creatorIncentive0) / 2));
            assertEq(token.balanceOf(user1), creatorBalFinal + payoutId0User1);
        } else if (data0.winOption == IBattles.BattleOption.Option1) {
            battles.claimWin(user3, battleId);
            assertEq(payoutId0User3, payoutId0User4);
            assertEq(payoutId0User3, (prizePool - creatorIncentive0) / 2);
            assertEq(payoutId0User1, 0);
            assertEq(token.balanceOf(user3), creatorBalFinal + payoutId0User3);
        }

        battleId[0] = 1;

        if (data1.winOption == IBattles.BattleOption.Option0) {
            battles.claimWin(user2, battleId);
            assertEq(payoutId1User1, payoutId1User2);
            assertEq(payoutId1User3, 0);
            assertEq(payoutId1User2, (prizePool - creatorIncentive1) / 2);
            assertEq(token.balanceOf(user1), creatorBalFinal + payoutId1User1);
        } else if (data1.winOption == IBattles.BattleOption.Option1) {
            assertEq(payoutId1User3, payoutId1User4);
            assertEq(payoutId1User1, 0);
            assertEq(payoutId1User3, (prizePool - creatorIncentive1) / 2);
            assertEq(token.balanceOf(user3), creatorBalFinal + payoutId1User3);
        }
        vm.stopPrank();
    }

    function test_PlatformFee() public {
        vm.prank(owner);
        battles.setPlatformFee(100); //1%

        uint256 limit = 10000; // -> 100%
        uint256 remaining = limit - (battles.marketMakerIncentive() + battles.platformFee());

        vm.startPrank(relayer);

        _predictionUtils(user1, user2, false);

        (uint256 prizePool,,) = battles.getPrizePoolAndOdds(0);

        uint256 magNum = (prizePool * remaining) / (limit);

        uint256 treasuryBalInit = token.balanceOf(treasury);

        uint256 creatorIncentive0 = battles.getMarketMakerIncentive(0);
        uint256 platformFee0 = battles.getPlatformFee(0);
        uint256 platformFee1 = battles.getPlatformFee(1);

        assertEq(creatorIncentive0 + platformFee0 + magNum, prizePool);

        uint256[] memory battleIds = new uint256[](2);
        battleIds[0] = 0;
        battleIds[1] = 1;

        vm.stopPrank();

        vm.startPrank(owner);

        vm.expectRevert("Error: Unresolved battle");
        battles.claimPlatformFee(battleIds);

        skip(30 days);

        _test_resolveBattle(0);
        _test_resolveBattle(1);

        battles.claimPlatformFee(battleIds);

        uint256 treasuryBalFinal = token.balanceOf(treasury);

        assertEq(treasuryBalInit + platformFee0 + platformFee1, treasuryBalFinal);

        vm.expectRevert("Error: Already claimed");
        battles.claimPlatformFee(battleIds);

        vm.stopPrank();
    }

    function test_No_Winning_Condition() public {
        vm.startPrank(relayer);

        IBattles.BattleManifest memory manifest = IBattles.BattleManifest(IBattles.BattleType.Artist, "BIGGY", "2PAC");
        IBattles.BattleOption option = IBattles.BattleOption.Option1;

        // when all betters choose the same option
        _test_CreateBattle(user1, minAmount, manifest, option, true);
        _test_MakePrediction(user2, 0, option, minAmount);

        vm.stopPrank();

        vm.prank(owner);

        skip(30 days);

        _test_resolveBattle(0);

        IBattles.BattleData memory data0 = battles.getBattle(0);

        assert(data0.winOption == IBattles.BattleOption.Default);
        assert(data0.isRefundable);

        uint256 payoutId0User1 = battles.getPayout(user1, 0);
        uint256 payoutId0User2 = battles.getPayout(user2, 0);

        assertEq(payoutId0User1, payoutId0User2);
        assertEq(payoutId0User1, 0);

        assertEq(battles.getMarketMakerIncentive(0), 0);
        assertEq(battles.getPlatformFee(0), 0);

        assertEq(battles.getRefund(user1, 0), minAmount);
        assertEq(battles.getRefund(user2, 0), minAmount);

        uint256[] memory battleIds = new uint256[](1);
        battleIds[0] = 0;

        uint256 user1BalInit = token.balanceOf(user1);

        vm.startPrank(relayer);
        battles.claimRefund(user1, battleIds);

        vm.expectRevert("Error: Invalid operation");
        battles.claimRefund(user1, battleIds);

        uint256 user1BalFinal = token.balanceOf(user1);

        assertEq(user1BalFinal - user1BalInit, minAmount);

        vm.stopPrank();
    }

    function test_Pauser() public {
        bytes4[] memory sigs = new bytes4[](1);
        sigs[0] = IBattles.makePrediction.selector;

        assert(!battles.paused(sigs[0]));

        vm.prank(relayer);
        vm.expectRevert();
        battles.pause(sigs);

        vm.prank(owner);
        battles.pause(sigs);

        assert(battles.paused(sigs[0]));

        vm.startPrank(relayer);
        IBattles.BattleManifest memory manifest =
            IBattles.BattleManifest(IBattles.BattleType.Track, "GOODDAY", "BADDAY");
        IBattles.BattleOption option = IBattles.BattleOption.Option1;

        _test_CreateBattle(user1, minAmount, manifest, option, true);
        option = IBattles.BattleOption.Option0;

        vm.expectRevert();
        battles.makePrediction(user2, 0, option, minAmount);

        vm.expectRevert();
        battles.unpause(sigs);

        vm.stopPrank();

        vm.prank(owner);

        battles.unpause(sigs);
        assert(!battles.paused(sigs[0]));

        _test_MakePrediction(user2, 0, option, minAmount);

        assertEq((battles.getUserPrediction(user2, 0)).amount, minAmount);
    }
}
