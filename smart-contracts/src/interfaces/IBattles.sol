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

    struct BattleTimeline {
        uint64 minTimeForBets;
        uint64 interval;
        uint64 maxIntervals;
    }

    struct BattleData {
        address creator;
        bool hasClaimedIncentive;
        bool hasClaimedPlatformFee;
        BattleManifest manifest;
        uint256 option0Count;
        uint256 option1Count;
        uint256 option0PrizePool;
        uint256 option1PrizePool;
        uint64 startTimestamp;
        uint64 closeTimestamp;
        uint256 aPIRequestId;
        bool isRefundable;
        BattleOption winOption;
    }

    event ClaimMarketMakerIncentive(uint256 indexed battleId, uint256 incentive);

    event ClaimPlatformFee(uint256 indexed battleId, uint256 fee);

    event ClaimWin(address indexed who, uint256 indexed battleId, uint256 payout);

    event ClaimRefund(address indexed who, uint256 indexed battleId, uint256 refund);

    event CreateBattle(
        address indexed creator,
        BattleType indexed battleType,
        uint256 battleId,
        bytes32 indexed hash,
        BattleManifest manifest
    );

    event MakePrediction(
        address indexed who, uint256 indexed battleId, uint256 amount, BattleOption indexed option, uint256[] ticketIds
    );

    event UpdateAmount(address indexed who, uint256 indexed battleId, uint256 amount, uint256[] ticketIds);

    event ResolveBattle(
        uint256 indexed battleId, BattleOption indexed winOption, uint256 indexed aPIRequestId, uint256 timestamp
    );

    event SetMinAmount(uint256 minAmount);

    event SetTimeline(BattleTimeline timeline);

    event SetMarketMakerIncentive(uint8 marketMakerIncentive);

    event SetPlatformFee(uint8 platformFee);

    event SetTreasury(address indexed treasury);

    function createBattle(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256 amount,
        bool useNextWindow
    ) external;

    function createBattleWithTickets(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256[] memory ticketIds,
        bool useNextWindow
    ) external;

    function claimMarketMakerIncentives(uint256[] calldata battleIds_) external;

    function claimPlatformFee(uint256[] calldata battleIds_) external;

    function claimWin(address who, uint256[] calldata battleIds_) external;

    function claimRefund(address who, uint256[] calldata battleIds_) external;

    function makePrediction(address who, uint256 battleId, BattleOption option, uint256 amount) external;

    function makePredictionWithTickets(address who, uint256 battleId, uint256[] calldata ticketIds, BattleOption option)
        external;

    function setMinAmount(uint256 _minAmount) external;

    function setTimeline(BattleTimeline calldata _timeline) external;

    function setMarketMakerIncentive(uint8 _marketMakerIncentive) external;

    function setPlatformFee(uint8 _platformFee) external;

    function setTreasury(address _treasury) external;

    function updateAmount(address who, uint256 battleId, uint256 amount) external;

    function updateAmountWithTickets(address who, uint256 battleId, uint256[] calldata ticketIds) external;

    function resolveBattle(uint256 battleId) external;

    function getBattle(uint256 battleId) external view returns (BattleData memory);

    function getMarketMakerIncentive(uint256 battleId) external view returns (uint256);

    function getPrizePoolAndOdds(uint256 battleId)
        external
        view
        returns (uint256 prizePool, uint256 option0Odd, uint256 option1Odd);

    function getPayout(address who, uint256 battleId) external view returns (uint256);

    function getUserPrediction(address user, uint256 battleId) external view returns (UserPrediction memory);

    function generateHash(BattleManifest calldata manifest, uint64 startTimestamp)
        external
        view
        returns (bytes32 hash, bool isActive);
}
