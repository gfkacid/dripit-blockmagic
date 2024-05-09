// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";

enum BattleMode {
    Artist,
    Track
}

enum BattleOption {
    Nil,
    Option0,
    Option1
}

struct BattleManifest {
    uint256 option0Id;
    uint256 option1Id;
}

struct UserPrediction {
    BattleOption option;
    uint256 amount;
    bool isClosed;
}

struct BattleData {
    address creator;
    BattleMode mode;
    BattleManifest manifest;
    uint256 amountRaised;
    uint256 option0Count;
    uint256 option1Count;
    uint16 startTimestamp;
    uint16 closeTimestamp;
    uint256 aPIRequestId;
    BattleOption winner;
}

contract Battles is Context {
    using SafeERC20 for IERC20;

    uint256 public battleIds;
    uint256 public minCreationStake;
    uint16 public duration;
    IERC20 public token;

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // user => UserPredictions
    mapping(address => UserPrediction[]) _userToPredictions;

    // battleId => BattleData
    mapping(uint256 => BattleData) public battles;

    // hash to isActive (bool)
    mapping(bytes32 => bool) _isActive;

    // creator => battleIds
    mapping(address => uint256[]) _creatorToBattleIds;

    event CreateBattle(
        address indexed creator,
        BattleMode indexed mode,
        uint256 id,
        bytes32 indexed hash,
        BattleManifest manifest,
        uint256 amount
    );

    constructor(address _token, uint256 _minCreationStake, uint16 _duration) {
        token = IERC20(_token);
        minCreationStake = _minCreationStake;
        duration = _duration;
    }

    modifier onlyOption(BattleOption option) {
        require(BattleOption.Nil != option, "Error: Wrong option");
        _;
    }

    function createBattle(
        BattleManifest calldata manifest,
        BattleMode mode,
        BattleOption option,
        uint256 amount
    ) external onlyOption(option) {
        require(amount >= minCreationStake, "Error: Inssuficient amount input");
        (bytes32 hash, bool active) = generateHash(manifest);
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
            mode: mode,
            manifest: manifest,
            amountRaised: amount,
            option0Count: option0Count,
            option1Count: option1Count,
            startTimestamp: uint16(block.timestamp),
            closeTimestamp: uint16(block.timestamp) + duration,
            aPIRequestId: 0,
            winner: BattleOption.Nil
        });

        _creatorToBattleIds[_msgSender()].push(id);

        emit CreateBattle(_msgSender(), mode, id, hash, manifest, amount);
    }

    function makePrediction(
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) external onlyOption(option) {}

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

    function getPredictions(
        address user
    ) external view returns (UserPrediction[] memory) {
        return _userToPredictions[user];
    }

    function getPredictionByIndex(
        address user,
        uint256 index
    ) external view returns (UserPrediction memory) {
        return _userToIdToPrediction[user][index];
    }

    function generateHash(
        BattleManifest calldata manifest
    ) public view returns (bytes32 hash, bool) {
        // Sort from smallest to biggest
        (uint256 a, uint256 b) = manifest.option0Id < manifest.option1Id
            ? (manifest.option0Id, manifest.option1Id)
            : (manifest.option1Id, manifest.option0Id);
        hash = keccak256(abi.encodePacked(a, b));
        return (hash, _isActive[hash]);
    }
}
