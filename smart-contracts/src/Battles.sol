// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";

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
    uint16 startTimestamp;
    uint16 closeTimestamp;
    uint256 aPIRequestId;
    BattleOption winOption;
}

contract Battles is Context {
    using SafeERC20 for IERC20;

    uint256 public battleIds;
    uint256 public minBetAmount;
    uint16 public duration;
    IERC20 public token;

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // battleId => BattleData
    mapping(uint256 => BattleData) public battles;

    // hash to isActive (bool)
    mapping(bytes32 => bool) _isActive;

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
        address indexed player,
        uint256 indexed battleId,
        uint256 amount,
        BattleOption indexed option
    );

    event ResolveBattle(
        uint256 indexed battleId,
        BattleOption indexed winOption,
        uint256 indexed aPIRequestId,
        uint256 timestamp
    );

    constructor(address _token, uint256 _minBetAmount, uint16 _duration) {
        token = IERC20(_token);
        minBetAmount = _minBetAmount;
        duration = _duration;
    }

    modifier validBet(BattleOption option, uint256 amount) {
        require(BattleOption.Nil != option, "Error: Wrong option");
        require(amount >= minBetAmount, "Error: Inssuficient amount input");
        _;
    }

    function createBattle(
        BattleManifest calldata manifest,
        BattleType battleType,
        BattleOption option,
        uint256 amount
    ) external validBet(option, amount) {
        (bytes32 hash, bool active) = generateHash(manifest, battleType);
        require(!active, "Error: Manifest is already active");

        token.safeTransferFrom(_msgSender(), address(this), amount);
        _isActive[hash] = true;

        unchecked {
            battleIds++;
        }
        uint256 id = battleIds;

        (uint256 option0Count, uint256 option1Count) = option ==
            BattleOption.Option0
            ? (1, 0)
            : (0, 1);

        battles[id] = BattleData({
            creator: _msgSender(),
            battleType: battleType,
            manifest: manifest,
            prizePool: amount,
            option0Count: option0Count,
            option1Count: option1Count,
            startTimestamp: uint16(block.timestamp),
            closeTimestamp: uint16(block.timestamp) + duration,
            aPIRequestId: 0,
            winOption: BattleOption.Nil
        });

        _creatorToBattleIds[_msgSender()].push(id);

        emit CreateBattle(_msgSender(), battleType, id, hash, manifest);
        emit MakePrediction(_msgSender(), id, amount, option);
    }

    function makePrediction(
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) external validBet(option, amount) {
        BattleData storage battle = battles[battleId];
        require(
            battle.startTimestamp > uint16(block.timestamp),
            "Error: Entry is not open"
        );

        token.safeTransferFrom(_msgSender(), address(this), amount);

        unchecked {
            battle.prizePool += amount;
            if (option == BattleOption.Option0) {
                battle.option0Count++;
            } else {
                battle.option1Count++;
            }
        }

        emit MakePrediction(_msgSender(), battleId, amount, option);
    }

    function resolveBattle(uint256 battleId) external {
        BattleData memory battleMem = battles[battleId];
        require(
            battleMem.prizePool > 0 &&
                uint16(block.timestamp) >= battleMem.closeTimestamp,
            "Error: Invalid operation"
        );
        BattleData storage battleSto = battles[battleId];
        (BattleOption winOption, uint256 aPIRequestId) = _dummyChainlinkFunc(
            battleMem.startTimestamp,
            battleMem.closeTimestamp
        );

        battleSto.winOption = winOption;
        battleSto.aPIRequestId = aPIRequestId;

        emit ResolveBattle(battleId, winOption, aPIRequestId, block.timestamp);
    }

    function _dummyChainlinkFunc(
        uint16 start,
        uint16 close
    ) private view returns (BattleOption, uint256) {
        uint256 aPIRequestId = close - start + block.timestamp;
        if (uint16(block.timestamp) < close)
            return (BattleOption.Nil, aPIRequestId);
        if ((close - start) % 2 == 0)
            return (BattleOption.Option0, aPIRequestId);
        return (BattleOption.Option1, aPIRequestId);
    }

    function getCreations(
        address creator
    ) external view returns (BattleData[] memory creations) {
        uint256 len = _creatorToBattleIds[creator].length;
        creations = new BattleData[](uint32(len));
        uint256 index;

        for (uint256 i; i < len; ) {
            index = _creatorToBattleIds[creator][i];
            creations[i] = battles[index];
            unchecked {
                ++i;
            }
        }
    }

    function getCreationByIndex(
        address creator,
        uint256 index
    ) external view returns (BattleData memory) {
        return battles[_creatorToBattleIds[creator][index]];
    }

    function getPredictionByBattleId(
        address user,
        uint256 battleId
    ) external view returns (UserPrediction memory) {
        return _userToIdToPrediction[user][battleId];
    }

    function generateHash(
        BattleManifest calldata manifest,
        BattleType battleType
    ) public view returns (bytes32 hash, bool) {
        // Sort from smallest to biggest
        (string memory a, string memory b) = keccak256(
            abi.encodePacked(manifest.option0Id)
        ) < keccak256(abi.encodePacked(manifest.option1Id))
            ? (manifest.option0Id, manifest.option1Id)
            : (manifest.option1Id, manifest.option0Id);
        hash = keccak256(abi.encodePacked(a, b, battleType));
        return (hash, _isActive[hash]);
    }
}
