// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IBattlesTicket} from "./interfaces/IBattlesTicket.sol";
import {IBattles} from "./interfaces/IBattles.sol";

contract Battles is AccessControlEnumerable, IBattles {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public immutable token;
    IBattlesTicket public immutable ticket;
    uint256 public battleIds;
    uint256 public minAmount;
    uint64 public duration = 1 weeks;
    uint64 public futureLimit = 2 weeks;
    uint8 public marketMakerIncentive = 100; // 1% == 100

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // battleId => BattleData
    mapping(uint256 => BattleData) _battles;

    // hash to index to stat time
    mapping(bytes32 => uint64) _schedules;

    constructor(
        address defaultAdmin,
        address _token,
        address _ticket,
        uint256 _minAmount
    ) {
        token = IERC20(_token);
        ticket = IBattlesTicket(_ticket);
        minAmount = _minAmount;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier validParams(BattleOption option, uint256 amount) {
        require(BattleOption.Default != option, "Error: Wrong option");
        require(amount >= minAmount, "Error: Inssuficient amount input");
        _;
    }

    modifier openWindow(uint256 battleId) {
        BattleData memory data = _battles[battleId];
        require(
            data.startTimestamp < uint64(block.timestamp) &&
                data.closeTimestamp > uint64(block.timestamp),
            "Error: Entry is not open"
        );
        _;
    }

    modifier activePlayer(address who, uint256 battleId) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][
            battleId
        ];
        require(
            predictionMem.option != BattleOption.Default,
            "Error: Make a prediction instead"
        );
        _;
    }

    function claimMarketMakerIncentives(
        uint256[] calldata battleIds_
    ) external {
        uint256 incentive;
        uint256 battleId;
        uint256 length = battleIds_.length;
        BattleData memory battleMem;

        for (uint256 i; i < length; ) {
            battleId = battleIds_[i];
            incentive = getMarketMakerIncentive(battleId);
            battleMem = _battles[battleId];
            require(
                !battleMem.hasClaimedIncentive && incentive > 0,
                "Error: Invalid operation"
            );
            _battles[battleId].hasClaimedIncentive = true;
            emit ClaimMarketMakerIncentive(battleId, incentive);
            token.safeTransfer(battleMem.creator, incentive);

            unchecked {
                ++i;
            }
        }
    }

    function claimWin(address who, uint256[] calldata battleIds_) external {
        uint256 payout;
        uint256 battleId;
        uint256 length = battleIds_.length;

        for (uint256 i; i < length; ) {
            battleId = battleIds_[i];
            payout = getPayout(who, battleId);
            require(
                !_userToIdToPrediction[who][battleId].isClosed && payout > 0,
                "Error: Invalid operation"
            );
            _userToIdToPrediction[who][battleId].isClosed = true;
            emit ClaimWin(who, battleId, payout);
            token.safeTransfer(who, payout);

            unchecked {
                ++i;
            }
        }
    }

    function createBattle(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256 amount,
        uint64 secondsBeforeStart
    ) external validParams(option, amount) {
        uint64 startTimestamp = uint64(block.timestamp) + secondsBeforeStart;
        (bytes32 hash, bool active) = generateHash(manifest, startTimestamp);
        require(!active, "Error: Manifest is already active");

        token.safeTransferFrom(creator, address(this), amount);

        _schedules[hash] = startTimestamp;

        uint256 id = battleIds;
        unchecked {
            battleIds++;
        }

        (
            uint256 option0PrizePool,
            uint256 option1PrizePool,
            uint256 option0Count,
            uint256 option1Count
        ) = option == BattleOption.Option0
                ? (amount, uint256(0), 1, 0)
                : (uint256(0), amount, 0, 1);

        _battles[id] = BattleData({
            creator: creator,
            hasClaimedIncentive: false,
            manifest: manifest,
            option0PrizePool: option0PrizePool,
            option1PrizePool: option1PrizePool,
            option0Count: option0Count,
            option1Count: option1Count,
            startTimestamp: startTimestamp,
            closeTimestamp: startTimestamp + duration,
            aPIRequestId: 0,
            winOption: BattleOption.Default
        });

        emit CreateBattle(creator, manifest.battleType, id, hash, manifest);

        _userToIdToPrediction[creator][id] = UserPrediction({
            option: option,
            amount: amount,
            isClosed: false
        });

        emit MakePrediction(creator, id, amount, option);
    }

    function makePrediction(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) external {
        token.safeTransferFrom(who, address(this), amount);
        _makePrediction(who, battleId, option, amount);
    }

    function makePredictionWithTickets(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256[] calldata ids
    ) external {
        uint256 amount = ticket.burnTickets(ids, who);
        _makePrediction(who, battleId, option, amount);
    }

    function setMinAmount(uint256 _minAmount) external onlyRole(ADMIN_ROLE) {
        minAmount = _minAmount;
        emit SetMinAmount(_minAmount);
    }

    function setDuration(uint64 _duration) external onlyRole(ADMIN_ROLE) {
        duration = _duration;
        emit SetDuration(_duration);
    }

    function setFutureLimit(uint64 _futurelimit) external onlyRole(ADMIN_ROLE) {
        futureLimit = _futurelimit;
        emit SetFutureLimit(_futurelimit);
    }

    function setMarketMakerIncentive(
        uint8 _marketMakerIncentive
    ) external onlyRole(ADMIN_ROLE) {
        require(
            _marketMakerIncentive > 0 && _marketMakerIncentive <= 1000,
            "Invalid input"
        );
        marketMakerIncentive = _marketMakerIncentive;
        emit SetMarketMakerIncentive(_marketMakerIncentive);
    }

    function updateAmount(
        address who,
        uint256 battleId,
        uint256 amount,
        bool topUp
    ) external openWindow(battleId) activePlayer(who, battleId) {
        BattleData storage battle = _battles[battleId];
        UserPrediction storage prediction = _userToIdToPrediction[who][
            battleId
        ];
        UserPrediction memory predictionMem = _userToIdToPrediction[who][
            battleId
        ];

        if (topUp) {
            token.safeTransferFrom(who, address(this), amount);
            unchecked {
                if (predictionMem.option == BattleOption.Option0) {
                    battle.option0PrizePool += amount;
                } else {
                    battle.option1PrizePool += amount;
                }
                prediction.amount += amount;
            }
        } else {
            require(
                predictionMem.amount >= amount,
                "Error: Insufficient balance"
            );

            if (predictionMem.amount == amount) {
                prediction.isClosed = true;
                if (predictionMem.option == BattleOption.Option0) {
                    battle.option0Count--;
                } else {
                    battle.option1Count--;
                }
            }

            prediction.amount -= amount;

            if (predictionMem.option == BattleOption.Option0) {
                battle.option0PrizePool -= amount;
            } else {
                battle.option1PrizePool -= amount;
            }

            token.safeTransfer(who, amount);
        }

        emit UpdateAmount(who, battleId, amount, topUp);
    }

    function updateOption(
        address who,
        uint256 battleId
    ) external openWindow(battleId) activePlayer(who, battleId) {
        BattleData storage battle = _battles[battleId];
        UserPrediction memory prediction = _userToIdToPrediction[who][battleId];

        if (prediction.option == BattleOption.Option0) {
            unchecked {
                battle.option0Count--;
                battle.option1Count++;
            }
            battle.option0PrizePool -= prediction.amount;
            battle.option1PrizePool += prediction.amount;
            _userToIdToPrediction[who][battleId].option = BattleOption.Option1;
            emit UpdateOption(
                who,
                battleId,
                BattleOption.Option0,
                BattleOption.Option1
            );
        } else {
            unchecked {
                battle.option1Count--;
                battle.option0Count++;
            }
            battle.option1PrizePool -= prediction.amount;
            battle.option0PrizePool += prediction.amount;
            _userToIdToPrediction[who][battleId].option = BattleOption.Option0;
            emit UpdateOption(
                who,
                battleId,
                BattleOption.Option1,
                BattleOption.Option0
            );
        }
    }

    function resolveBattle(uint256 battleId) external onlyRole(ADMIN_ROLE) {
        BattleData memory battleMem = _battles[battleId];
        require(
            battleMem.option0PrizePool + battleMem.option1PrizePool > 0 &&
                uint64(block.timestamp) >= battleMem.closeTimestamp,
            "Error: Invalid operation"
        );
        require(
            battleMem.winOption == BattleOption.Default,
            "Error: Battle closed already"
        );

        (BattleOption winOption, uint256 aPIRequestId) = _dummyChainlinkFunc(
            battleMem.startTimestamp,
            battleMem.closeTimestamp
        );

        BattleData storage battleSto = _battles[battleId];
        battleSto.winOption = winOption;
        battleSto.aPIRequestId = aPIRequestId;

        emit ResolveBattle(battleId, winOption, aPIRequestId, block.timestamp);
    }

    function getBattle(
        uint256 battleId
    ) external view returns (BattleData memory) {
        return _battles[battleId];
    }

    function getMarketMakerIncentive(
        uint256 battleId
    ) public view returns (uint256) {
        uint256 limit = 10000; // -> 100%
        (uint256 prizePool, , ) = getPrizePoolAndOdds(battleId);
        return ((prizePool * marketMakerIncentive) / limit);
    }

    function getPrizePoolAndOdds(
        uint256 battleId
    )
        public
        view
        returns (uint256 prizePool, uint256 option0Odd, uint256 option1Odd)
    {
        BattleData memory battle = _battles[battleId];
        unchecked {
            prizePool = battle.option0PrizePool + battle.option1PrizePool;
        }

        uint256 scale = 1e18;
        uint256 lot = prizePool * scale;

        option0Odd = battle.option0PrizePool == 0
            ? 0
            : lot / battle.option0PrizePool;
        option1Odd = battle.option1PrizePool == 0
            ? 0
            : lot / battle.option1PrizePool;
    }

    function getPayout(
        address who,
        uint256 battleId
    ) public view returns (uint256) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][
            battleId
        ];
        BattleData memory battleMem = _battles[battleId];

        if (
            battleMem.winOption == BattleOption.Default ||
            battleMem.winOption != predictionMem.option
        ) {
            return 0;
        }

        uint256 _marketMakerIncentive = uint256(marketMakerIncentive);
        (, uint256 option0Odd, uint256 option1Odd) = getPrizePoolAndOdds(
            battleId
        );

        uint256 limit = 10000; // -> 100%
        uint256 scale = 1e18;

        if (predictionMem.option == BattleOption.Option0) {
            return ((((option0Odd * predictionMem.amount) *
                (limit - _marketMakerIncentive)) / limit) / scale);
        }
        return ((((option1Odd * predictionMem.amount) *
            (limit - _marketMakerIncentive)) / limit) / scale);
    }

    function getUserPrediction(
        address user,
        uint256 battleId
    ) external view returns (UserPrediction memory) {
        return _userToIdToPrediction[user][battleId];
    }

    function generateHash(
        BattleManifest calldata manifest,
        uint64 startTimestamp
    ) public view returns (bytes32 hash, bool isActive) {
        require(
            startTimestamp < uint64(block.timestamp) + futureLimit,
            "Error: Too far in the future"
        );

        // Sort from smallest to biggest
        (string memory a, string memory b) = keccak256(
            abi.encodePacked(manifest.option0Id)
        ) < keccak256(abi.encodePacked(manifest.option1Id))
            ? (manifest.option0Id, manifest.option1Id)
            : (manifest.option1Id, manifest.option0Id);
        hash = keccak256(abi.encodePacked(a, b, manifest.battleType));

        uint64 lastSchedule = _schedules[hash];

        if (
            (lastSchedule < startTimestamp &&
                lastSchedule + duration > startTimestamp) ||
            (startTimestamp < lastSchedule &&
                startTimestamp + duration > lastSchedule) ||
            lastSchedule == startTimestamp
        ) {
            isActive = true;
        }
    }

    function _dummyChainlinkFunc(
        uint64 start,
        uint64 close
    ) private view returns (BattleOption, uint256) {
        uint256 aPIRequestId = close - start + block.timestamp;
        if (uint64(block.timestamp) < close)
            return (BattleOption.Default, aPIRequestId);
        if ((close - start) % 2 == 0)
            return (BattleOption.Option0, aPIRequestId);
        return (BattleOption.Option1, aPIRequestId);
    }

    function _makePrediction(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) private openWindow(battleId) validParams(option, amount) {
        BattleData storage battle = _battles[battleId];
        require(
            _userToIdToPrediction[who][battleId].amount == 0,
            "Update entries instead"
        );

        _userToIdToPrediction[who][battleId] = UserPrediction({
            option: option,
            amount: amount,
            isClosed: false
        });

        unchecked {
            if (option == BattleOption.Option0) {
                battle.option0Count++;
                battle.option0PrizePool += amount;
            } else {
                battle.option1Count++;
                battle.option1PrizePool += amount;
            }
        }

        emit MakePrediction(who, battleId, amount, option);
    }
}
