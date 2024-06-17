// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IBattles {
    enum BattleType {
        Artist,
        Track
    }

    enum BattleOption {
        Default,
        Option0,
        Option1
    }

    struct BattleManifest {
        BattleType battleType;
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
        bool hasClaimedIncentive;
        BattleManifest manifest;
        uint256 option0Count;
        uint256 option1Count;
        uint256 option0PrizePool;
        uint256 option1PrizePool;
        uint64 startTimestamp;
        uint64 closeTimestamp;
        uint256 aPIRequestId;
        BattleOption winOption;
    }

    event ClaimMarketMakerIncentive(
        uint256 indexed battleId,
        uint256 incentive
    );

    event ClaimWin(
        address indexed who,
        uint256 indexed battleId,
        uint256 payout
    );

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

    event SetMinAmount(uint256 minAmount);

    event SetDuration(uint64 duration);

    event SetFutureLimit(uint64 futureLimit);

    event SetMarketMakerIncentive(uint8 marketMakerIncentive);

    function createBattle(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256 amount,
        uint64 secondsBeforeStart
    ) external;

    function makePrediction(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256 amount
    ) external;

    function setMinAmount(uint256 _minAmount) external;

    function setDuration(uint64 _duration) external;

    function setFutureLimit(uint64 _futurelimit) external;

    function setMarketMakerIncentive(uint8 _marketMakerIncentive) external;

    function updateAmount(
        address who,
        uint256 battleId,
        uint256 amount,
        bool topUp
    ) external;

    function updateOption(address who, uint256 battleId) external;

    function resolveBattle(uint256 battleId) external;

    function getBattle(
        uint256 battleId
    ) external view returns (BattleData memory);

    function getMarketMakerIncentive(
        uint256 battleId
    ) external view returns (uint256);

    function getPrizePoolAndOdds(
        uint256 battleId
    )
        external
        view
        returns (uint256 prizePool, uint256 option0Odd, uint256 option1Odd);

    function getPayout(
        address who,
        uint256 battleId
    ) external view returns (uint256);

    function getUserPrediction(
        address user,
        uint256 battleId
    ) external view returns (UserPrediction memory);

    function generateHash(
        BattleManifest calldata manifest,
        uint64 startTimestamp
    ) external view returns (bytes32 hash, bool isActive);
}
