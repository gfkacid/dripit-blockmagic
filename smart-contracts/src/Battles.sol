// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

enum BattleType {
    Artist,
    Track
}

enum BattleOption {
    Nil,
    Option0,
    Option1
}

struct BattleManifest {
    string option0Id;
    string option1Id;
}

struct UserPrediction {
    BattleOption option;
    uint256 amount;
    bool isClosed;
}

struct BattleData {
    address creator;
    BattleType battleType;
    BattleManifest manifest;
    uint256 prizePool;
    uint256 option0Count;
    uint256 option1Count;
    uint64 startTimestamp;
    uint64 closeTimestamp;
    uint256 aPIRequestId;
    BattleOption winOption;
}

contract Battles is Ownable {
    using SafeERC20 for IERC20;

    uint256 public battleIds;
    uint256 public minAmount;
    uint64 public constant DURATION = 1 weeks;
    uint64 public constant FUTURE_LIMIT = 2 weeks;
    IERC20 public token;

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // battleId => BattleData
    mapping(uint256 => BattleData) _battles;

    // hash to index to stat time
    mapping(bytes32 => uint64) _schedules;

    // creator => battleIds
    mapping(address => uint256[]) _creatorToBattleIds;

    event CreateBattle(
        address indexed creator,
        BattleType indexed battleType,
        uint256 battleId,
        bytes32 indexed hash,
        BattleManifest manifest
    );

    event MakePrediction(
        address indexed who,
        uint256 indexed battleId,
        uint256 amount,
        BattleOption indexed option
    );

    event UpdateAmount(
        address indexed who,
        uint256 indexed battleId,
        uint256 amount,
        bool indexed topUp
    );

    event UpdateOption(
        address indexed who,
        uint256 indexed battleId,
        BattleOption oldOption,
        BattleOption newOption
    );

    event ResolveBattle(
        uint256 indexed battleId,
        BattleOption indexed winOption,
        uint256 indexed aPIRequestId,
        uint256 timestamp
    );

    constructor(
        address initialOwner,
        address _token,
        uint256 _minAmount
    ) Ownable(initialOwner) {
        token = IERC20(_token);
        minAmount = _minAmount;
    }

    modifier validParams(BattleOption option, uint256 amount) {
        require(BattleOption.Nil != option, "Error: Wrong option");
        require(amount >= minAmount, "Error: Inssuficient amount input");
        _;
    }

    modifier openWindow(uint256 battleId) {
        BattleData memory data = _battles[battleId];
        require(
            data.startTimestamp > uint64(block.timestamp),
            "Error: Entry is not open"
        );
        _;
    }

    modifier previousPredictor(address who, uint256 battleId) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][
            battleId
        ];
        require(
            predictionMem.option != BattleOption.Nil,
            "Error: Make a prediction instead"
        );
        _;
    }

    function createBattle(
        address creator,
        BattleManifest calldata manifest,
        BattleType battleType,
        BattleOption option,
        uint256 amount,
        uint64 secondsBeforeStart
    ) external validParams(option, amount) {
        uint64 startTimestamp = uint64(block.timestamp) + secondsBeforeStart;
        (bytes32 hash, bool active) = generateHash(
            manifest,
            battleType,
            startTimestamp
        );
        require(!active, "Error: Manifest is already active");

        token.safeTransferFrom(creator, address(this), amount);

        _schedules[hash] = startTimestamp;

        uint256 id = battleIds;
        unchecked {
            battleIds++;
        }

        (uint256 option0Count, uint256 option1Count) = option ==
            BattleOption.Option0
            ? (1, 0)
            : (0, 1);

        _battles[id] = BattleData({
            creator: creator,
            battleType: battleType,
            manifest: manifest,
            prizePool: amount,
            option0Count: option0Count,
            option1Count: option1Count,
            startTimestamp: startTimestamp,
            closeTimestamp: startTimestamp + DURATION,
            aPIRequestId: 0,
            winOption: BattleOption.Nil
        });

        _creatorToBattleIds[creator].push(id);

        emit CreateBattle(creator, battleType, id, hash, manifest);
        emit MakePrediction(creator, id, amount, option);
    }

    function makePrediction(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) external openWindow(battleId) validParams(option, amount) {
        BattleData storage battle = _battles[battleId];
        require(
            _userToIdToPrediction[who][battleId].amount == 0,
            "Update entries instead"
        );

        token.safeTransferFrom(who, address(this), amount);

        _userToIdToPrediction[who][battleId] = UserPrediction({
            option: option,
            amount: amount,
            isClosed: false
        });

        unchecked {
            battle.prizePool += amount;
            if (option == BattleOption.Option0) {
                battle.option0Count++;
            } else {
                battle.option1Count++;
            }
        }

        emit MakePrediction(who, battleId, amount, option);
    }

    function updateAmount(
        address who,
        uint256 battleId,
        uint256 amount,
        bool topUp
    ) external openWindow(battleId) previousPredictor(who, battleId) {
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
                battle.prizePool += amount;
                prediction.amount += amount;
            }
        } else {
            require(
                predictionMem.amount >= amount,
                "Error: Insufficient balance"
            );

            if (predictionMem.amount - amount == 0) {
                prediction.isClosed = true;
            }

            unchecked {
                battle.prizePool -= amount;
                prediction.amount -= amount;
            }

            token.safeTransfer(who, amount);
        }

        emit UpdateAmount(who, battleId, amount, topUp);
    }

    function updateOption(
        address who,
        uint256 battleId
    ) external openWindow(battleId) previousPredictor(who, battleId) {
        BattleData storage battle = _battles[battleId];
        UserPrediction memory prediction = _userToIdToPrediction[who][battleId];

        if (prediction.option == BattleOption.Option0) {
            unchecked {
                battle.option0Count--;
                battle.option1Count++;
            }
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
            _userToIdToPrediction[who][battleId].option = BattleOption.Option0;
            emit UpdateOption(
                who,
                battleId,
                BattleOption.Option1,
                BattleOption.Option0
            );
        }
    }

    function resolveBattle(uint256 battleId) external onlyOwner {
        BattleData memory battleMem = _battles[battleId];
        require(
            battleMem.prizePool > 0 &&
                uint64(block.timestamp) >= battleMem.closeTimestamp,
            "Error: Invalid operation"
        );
        BattleData storage battleSto = _battles[battleId];
        (BattleOption winOption, uint256 aPIRequestId) = _dummyChainlinkFunc(
            battleMem.startTimestamp,
            battleMem.closeTimestamp
        );

        battleSto.winOption = winOption;
        battleSto.aPIRequestId = aPIRequestId;

        emit ResolveBattle(battleId, winOption, aPIRequestId, block.timestamp);
    }

    function getBattle(
        uint256 battleId
    ) external view returns (BattleData memory) {
        return _battles[battleId];
    }

    function getCreations(
        address creator
    ) external view returns (BattleData[] memory creations) {
        uint256 len = _creatorToBattleIds[creator].length;
        creations = new BattleData[](uint32(len));
        uint256 index;

        for (uint256 i; i < len; ) {
            index = _creatorToBattleIds[creator][i];
            creations[i] = _battles[index];
            unchecked {
                ++i;
            }
        }
    }

    function getCreationByIndex(
        address creator,
        uint256 index
    ) external view returns (BattleData memory) {
        return _battles[_creatorToBattleIds[creator][index]];
    }

    function getPredictionByBattleId(
        address user,
        uint256 battleId
    ) external view returns (UserPrediction memory) {
        return _userToIdToPrediction[user][battleId];
    }

    function generateHash(
        BattleManifest calldata manifest,
        BattleType battleType,
        uint64 startTimestamp
    ) public view returns (bytes32 hash, bool isActive) {
        require(
            startTimestamp < uint64(block.timestamp) + FUTURE_LIMIT,
            "Error: Too far in the future"
        );

        // Sort from smallest to biggest
        (string memory a, string memory b) = keccak256(
            abi.encodePacked(manifest.option0Id)
        ) < keccak256(abi.encodePacked(manifest.option1Id))
            ? (manifest.option0Id, manifest.option1Id)
            : (manifest.option1Id, manifest.option0Id);
        hash = keccak256(abi.encodePacked(a, b, battleType));

        uint64 lastSchedule = _schedules[hash];

        if (
            (lastSchedule < startTimestamp &&
                lastSchedule + DURATION > startTimestamp) ||
            (startTimestamp < lastSchedule &&
                startTimestamp + DURATION > lastSchedule) ||
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
            return (BattleOption.Nil, aPIRequestId);
        if ((close - start) % 2 == 0)
            return (BattleOption.Option0, aPIRequestId);
        return (BattleOption.Option1, aPIRequestId);
    }
}
