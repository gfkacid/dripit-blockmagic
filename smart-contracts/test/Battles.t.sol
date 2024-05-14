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
        BattleManifest memory manifestA = BattleManifest("GOOD DAY", "BAD DAY");
        BattleType battleType = BattleType.Track;
        (bytes32 hashA, ) = battles.generateHash(
            manifestA,
            battleType,
            uint64(block.timestamp)
        );

        BattleManifest memory manifestB = BattleManifest("BAD DAY", "GOOD DAY");
        battleType = BattleType.Track;
        (bytes32 hashB, ) = battles.generateHash(
            manifestB,
            battleType,
            uint64(block.timestamp)
        );

        BattleManifest memory manifestC = BattleManifest("2PAC", "BIGGY");
        battleType = BattleType.Artist;
        (bytes32 hashC, ) = battles.generateHash(
            manifestC,
            battleType,
            uint64(block.timestamp)
        );

        BattleManifest memory manifestD = BattleManifest("BIGGY", "2PAC");
        battleType = BattleType.Artist;
        (bytes32 hashD, ) = battles.generateHash(
            manifestD,
            battleType,
            uint64(block.timestamp)
        );

        BattleManifest memory manifestE = BattleManifest("BIGGY", "2PAC");
        battleType = BattleType.Track;
        (bytes32 hashE, ) = battles.generateHash(
            manifestE,
            battleType,
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
        BattleManifest memory manifest = BattleManifest("BIGGY", "2PAC");
        BattleType battleType = BattleType.Artist;
        BattleOption option = BattleOption.Nil;
        uint256 amount = minAmount - 1;
        uint64 secondsBeforeStart = battles.FUTURE_LIMIT();

        token.approve(address(battles), token.totalSupply());

        // should NOT accept an invalid option
        vm.expectRevert(bytes("Error: Wrong option"));
        battles.createBattle(
            address(user1),
            manifest,
            battleType,
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
            battleType,
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
            battleType,
            option,
            amount,
            secondsBeforeStart
        );

        secondsBeforeStart /= 2;
        battles.createBattle(
            user1,
            manifest,
            battleType,
            option,
            amount,
            secondsBeforeStart
        );

        assertEq(battles.battleIds(), 1);

        BattleData memory data = battles.getBattle(id);

        assertEq(data.creator, user1);
        assertEq(data.prizePool, amount);
        assertEq(data.option0Count, 1);
        assertEq(data.option1Count, 0);
        assertEq(
            data.startTimestamp,
            uint64(block.timestamp) + secondsBeforeStart
        );
        assertEq(data.closeTimestamp, data.startTimestamp + battles.DURATION());
        assertEq(
            abi.encodePacked(data.winOption),
            abi.encodePacked(BattleOption.Nil)
        );

        BattleData[] memory creations = battles.getCreations(user1);
        assertEq(creations[0].option0Count, 1);
        assertEq(
            creations[0].option0Count,
            (battles.getCreationByIndex(user1, 0)).option0Count
        );

        vm.startPrank(user2);
        token.approve(address(battles), token.totalSupply());
        vm.expectRevert(bytes("Error: Manifest is already active"));
        battles.createBattle(
            user2,
            manifest,
            battleType,
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
            battleType,
            option,
            amount,
            secondsBeforeStart
        );

        manifest = BattleManifest("BIG POPPA", "HIT EM UP");
        battleType = BattleType.Track;
        option = BattleOption.Option1;
        battles.createBattle(
            user2,
            manifest,
            battleType,
            option,
            amount,
            secondsBeforeStart
        );
        assertEq(battles.battleIds(), 2);
        assertEq((battles.getCreations(user2)).length, 1);
    }

    function test_MakePrediction() internal {
        _test_CreateBattle_And_Fails();

        // make prediction for battle ids 0 and 1
        uint256 id = 0;

        vm.startPrank(user3);

        BattleOption option = BattleOption.Nil;
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
        assertEq(data.prizePool, minAmount * 2);
        assertEq(data.option0Count, data.option1Count);

        vm.startPrank(user4);

        option = BattleOption.Option0;
        amount = minAmount;

        token.approve(address(battles), token.totalSupply());

        battles.makePrediction(user4, id, option, amount);
        battles.makePrediction(user4, id + 1, option, amount);

        vm.stopPrank();
    }

    function test_UpdateAmount() internal {
        test_MakePrediction();
        vm.prank(user2);

        vm.expectRevert("Error: Make a prediction instead");
        battles.updateAmount(user2, 0, minAmount, false);

        uint256 amount = minAmount;

        vm.startPrank(user3);

        assertEq(token.balanceOf(user3), amount);

        BattleData memory data = battles.getBattle(0);
        UserPrediction memory prediction = battles.getPredictionByBattleId(
            user3,
            0
        );
        battles.updateAmount(user3, 0, amount, true);

        assertEq(token.balanceOf(user3), 0);
        assertLt(data.prizePool, (battles.getBattle(0)).prizePool);
        assertLt(
            prediction.amount,
            (battles.getPredictionByBattleId(user3, 0)).amount
        );

        vm.expectRevert("Error: Insufficient balance");
        battles.updateAmount(user3, 0, amount * 3, false);

        battles.updateAmount(user3, 0, amount * 2, false);
        assertEq(token.balanceOf(user3), amount * 2);

        prediction = battles.getPredictionByBattleId(user3, 0);

        assertEq(prediction.amount, 0);
        assertTrue(prediction.isClosed);

        battles.makePrediction(user3, 0, BattleOption.Option0, amount);
        vm.stopPrank();
    }

    function test_UpdateOption() internal {
        test_UpdateAmount();
        vm.startPrank(user4);

        BattleData memory data = battles.getBattle(0);
        UserPrediction memory prediction = battles.getPredictionByBattleId(
            user4,
            0
        );
        battles.updateOption(user4, 0);
        assertNotEq(data.option0Count, (battles.getBattle(0)).option0Count);
        assertNotEq(data.option1Count, (battles.getBattle(0)).option1Count);
        assertNotEq(
            abi.encodePacked(prediction.option),
            abi.encodePacked((battles.getPredictionByBattleId(user4, 0)).option)
        );

        // increment time to start time
        uint64 timeInSeconds = battles.FUTURE_LIMIT() / 2;
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

    function test_resolveBattle() external {
        test_UpdateOption();
        vm.prank(user1);
        vm.expectRevert();
        battles.resolveBattle(0);

        vm.startPrank(owner);
        vm.expectRevert("Error: Invalid operation");
        battles.resolveBattle(33);

        vm.expectRevert("Error: Invalid operation");
        battles.resolveBattle(0);

        // increment time to close time
        uint64 timeInSeconds = battles.DURATION() + 5000;
        skip(timeInSeconds);

        battles.resolveBattle(0);
        battles.resolveBattle(1);

        BattleData memory data0 = battles.getBattle(0);
        BattleData memory data1 = battles.getBattle(1);

        assertNotEq(data0.aPIRequestId, 0);
        assertNotEq(data1.aPIRequestId, 0);

        assertNotEq(
            abi.encodePacked(data0.winOption),
            abi.encodePacked(BattleOption.Nil)
        );
        assertNotEq(
            abi.encodePacked(data1.winOption),
            abi.encodePacked(BattleOption.Nil)
        );
    }
}
