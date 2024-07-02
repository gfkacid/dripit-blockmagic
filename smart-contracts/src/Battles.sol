// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBattlesTicket} from "./interfaces/IBattlesTicket.sol";
import {IBattles} from "./interfaces/IBattles.sol";
import {DynamicPauser} from "./internal/DynamicPauser.sol";
import {TimeHelper} from "./libraries/TimeHelper.sol";

contract Battles is UUPSUpgradeable, AccessControlEnumerableUpgradeable, DynamicPauser, IBattles {
    using SafeERC20 for IERC20;

    IBattlesTicket public ticket;
    IERC20 public token;
    BattleTimeline public timeline =
        BattleTimeline({minTimeForBets: 48 hours, interval: 1 weeks, maxIntervals: 2 weeks});
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    uint64 constant INIT_MONDAY = 1719187200; //(GMT): Monday, June 24, 2024 12:00:00 AM
    uint8 public marketMakerIncentive = 100; // 1% = 100
    uint8 public platformFee = 0; // 1% = 100
    bool _initialized;
    address public treasury;
    uint256 public battleIds;
    uint256 public minAmount;

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // battleId => BattleData
    mapping(uint256 => BattleData) _battles;

    // hash to index to start time
    mapping(bytes32 => uint64) _schedules;

    modifier validateFee(uint8 value) {
        uint256 feeLimit = 1000; // 10%
        require(value <= feeLimit, "Invalid input");
        _;
    }

    modifier validParams(BattleOption option, uint256 amount) {
        require(BattleOption.Default != option, "Error: Wrong option");
        require(amount >= minAmount, "Error: Inssuficient amount input");
        _;
    }

    modifier openWindow(uint256 battleId) {
        BattleData memory data = _battles[battleId];
        require(data.startTimestamp > uint64(block.timestamp), "Error: Entry is not open");
        _;
    }

    modifier activeUser(address who, uint256 battleId) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][battleId];
        require(predictionMem.option != BattleOption.Default, "Error: Make a prediction instead");
        _;
    }

    function initialize(
        address defaultAdmin,
        address relayer,
        address _token,
        address _ticket,
        address _treasury,
        uint256 _minAmount
    ) external initializer {
        require(!_initialized, "Initialized");
        _initialized = true;

        token = IERC20(_token);
        ticket = IBattlesTicket(_ticket);
        minAmount = _minAmount;
        treasury = _treasury;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(RELAYER_ROLE, relayer);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(RELAYER_ROLE, DEFAULT_ADMIN_ROLE);

        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();
    }

    function claimMarketMakerIncentives(uint256[] calldata battleIds_)
        external
        onlyRole(RELAYER_ROLE)
        whenNotPaused(this.claimMarketMakerIncentives.selector)
    {
        uint256 incentive;
        uint256 battleId;
        uint256 length = battleIds_.length;
        BattleData memory battleMem;

        for (uint256 i; i < length;) {
            battleId = battleIds_[i];
            incentive = getMarketMakerIncentive(battleId);
            battleMem = _battles[battleId];

            require(!battleMem.hasClaimedIncentive, "Error: Already claimed");

            _feeAndIncentiveChecks(battleMem.winOption, incentive);

            _battles[battleId].hasClaimedIncentive = true;

            emit ClaimMarketMakerIncentive(battleId, incentive);

            token.safeTransfer(battleMem.creator, incentive);

            unchecked {
                ++i;
            }
        }
    }

    function claimPlatformFee(uint256[] calldata battleIds_)
        external
        whenNotPaused(this.claimPlatformFee.selector)
        onlyRole(ADMIN_ROLE)
    {
        uint256 fee;
        uint256 battleId;
        uint256 length = battleIds_.length;

        for (uint256 i; i < length;) {
            battleId = battleIds_[i];
            fee = getPlatformFee(battleId);
            BattleData memory battleMem = _battles[battleId];

            require(!battleMem.hasClaimedPlatformFee, "Error: Already claimed");

            _feeAndIncentiveChecks(battleMem.winOption, fee);

            _battles[battleId].hasClaimedPlatformFee = true;

            emit ClaimPlatformFee(battleId, fee);

            token.safeTransfer(treasury, fee);

            unchecked {
                ++i;
            }
        }
    }

    function claimWin(address who, uint256[] calldata battleIds_)
        external
        onlyRole(RELAYER_ROLE)
        whenNotPaused(this.claimWin.selector)
    {
        uint256 payout;
        uint256 battleId;
        uint256 length = battleIds_.length;

        for (uint256 i; i < length;) {
            battleId = battleIds_[i];
            payout = getPayout(who, battleId);
            require(!_userToIdToPrediction[who][battleId].isClosed && payout != 0, "Error: Invalid operation");
            _userToIdToPrediction[who][battleId].isClosed = true;
            emit ClaimWin(who, battleId, payout);
            token.safeTransfer(who, payout);

            unchecked {
                ++i;
            }
        }
    }

    function claimRefund(address who, uint256[] calldata battleIds_)
        external
        onlyRole(RELAYER_ROLE)
        whenNotPaused(this.claimRefund.selector)
    {
        uint256 refund;
        uint256 battleId;
        uint256 length = battleIds_.length;

        for (uint256 i; i < length;) {
            battleId = battleIds_[i];
            refund = getRefund(who, battleId);
            require(!_userToIdToPrediction[who][battleId].isClosed && refund != 0, "Error: Invalid operation");
            _userToIdToPrediction[who][battleId].isClosed = true;
            emit ClaimRefund(who, battleId, refund);
            token.safeTransfer(who, refund);

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
        bool useNextWindow
    ) external whenNotPaused(this.createBattle.selector) {
        token.safeTransferFrom(creator, address(this), amount);
        _createBattle(creator, manifest, option, amount, useNextWindow, new uint256[](0));
    }

    function createBattleWithTickets(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256[] memory ticketIds,
        bool useNextWindow
    ) external whenNotPaused(this.createBattleWithTickets.selector) {
        uint256 amount = _ticketBurner(ticketIds, creator);
        _createBattle(creator, manifest, option, amount, useNextWindow, ticketIds);
    }

    function makePrediction(address who, uint256 battleId, BattleOption option, uint256 amount)
        external
        whenNotPaused(this.makePrediction.selector)
    {
        token.safeTransferFrom(who, address(this), amount);
        _makePrediction(who, battleId, option, amount, new uint256[](0));
    }

    function makePredictionWithTickets(address who, uint256 battleId, uint256[] memory ticketIds, BattleOption option)
        external
        whenNotPaused(this.makePredictionWithTickets.selector)
    {
        uint256 amount = _ticketBurner(ticketIds, who);
        _makePrediction(who, battleId, option, amount, ticketIds);
    }

    function updateAmount(address who, uint256 battleId, uint256 amount)
        external
        openWindow(battleId)
        activeUser(who, battleId)
        onlyRole(RELAYER_ROLE)
        whenNotPaused(this.updateAmount.selector)
    {
        BattleData storage battle = _battles[battleId];

        token.safeTransferFrom(who, address(this), amount);
        unchecked {
            if (_userToIdToPrediction[who][battleId].option == BattleOption.Option0) {
                battle.option0PrizePool = battle.option0PrizePool + amount;
            } else {
                battle.option1PrizePool = battle.option1PrizePool + amount;
            }
            _userToIdToPrediction[who][battleId].amount = _userToIdToPrediction[who][battleId].amount + amount;
        }

        emit UpdateAmount(who, battleId, amount, new uint256[](0));
    }

    function updateAmountWithTickets(address who, uint256 battleId, uint256[] calldata ticketIds)
        external
        openWindow(battleId)
        activeUser(who, battleId)
        onlyRole(RELAYER_ROLE)
        whenNotPaused(this.updateAmountWithTickets.selector)
    {
        BattleData storage battle = _battles[battleId];

        uint256 amount = _ticketBurner(ticketIds, who);
        unchecked {
            if (_userToIdToPrediction[who][battleId].option == BattleOption.Option0) {
                battle.option0PrizePool = battle.option0PrizePool + amount;
            } else {
                battle.option1PrizePool = battle.option1PrizePool + amount;
            }
            _userToIdToPrediction[who][battleId].amount = _userToIdToPrediction[who][battleId].amount + amount;
        }

        emit UpdateAmount(who, battleId, amount, ticketIds);
    }

    function resolveBattle(uint256 battleId) external onlyRole(ADMIN_ROLE) whenNotPaused(this.resolveBattle.selector) {
        BattleData memory battleMem = _battles[battleId];
        require(battleMem.option0PrizePool + battleMem.option1PrizePool != 0, "Error: Empty pool");
        require(uint64(block.timestamp) >= battleMem.closeTimestamp, "Error: Not yet");
        require(battleMem.winOption == BattleOption.Default && !battleMem.isRefundable, "Error: Battle closed already");

        (bool yes,) = _checkBothSidesFilled(battleId);
        BattleData storage battleSto = _battles[battleId];

        if (yes) {
            (BattleOption winOption, uint256 aPIRequestId) =
                _dummyChainlinkFunc(battleMem.startTimestamp, battleMem.closeTimestamp);

            battleSto.winOption = winOption;
            battleSto.aPIRequestId = aPIRequestId;

            emit ResolveBattle(battleId, winOption, aPIRequestId, block.timestamp);
        } else {
            battleSto.isRefundable = true;
            emit ResolveBattle(battleId, BattleOption.Default, 0, block.timestamp);
        }
    }

    function pause(bytes4[] memory selectors) external onlyRole(PAUSER_ROLE) {
        uint256 length = selectors.length;
        for (uint256 i; i < length;) {
            _pause(selectors[i]);
            unchecked {
                ++i;
            }
        }
    }

    function unpause(bytes4[] memory selectors) external onlyRole(PAUSER_ROLE) {
        uint256 length = selectors.length;
        for (uint256 i; i < length;) {
            _unpause(selectors[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setMinAmount(uint256 _minAmount) external onlyRole(ADMIN_ROLE) {
        minAmount = _minAmount;
        emit SetMinAmount(_minAmount);
    }

    function setTimeline(BattleTimeline calldata _timeline) external onlyRole(ADMIN_ROLE) {
        timeline = _timeline;
        emit SetTimeline(_timeline);
    }

    function setMarketMakerIncentive(uint8 _marketMakerIncentive)
        external
        validateFee(_marketMakerIncentive)
        onlyRole(ADMIN_ROLE)
    {
        require(_marketMakerIncentive != 0 && _marketMakerIncentive <= 1000, "Invalid input");
        marketMakerIncentive = _marketMakerIncentive;
        emit SetMarketMakerIncentive(_marketMakerIncentive);
    }

    function setPlatformFee(uint8 _platformFee) external validateFee(_platformFee) onlyRole(ADMIN_ROLE) {
        platformFee = _platformFee;
        emit SetPlatformFee(_platformFee);
    }

    function setTreasury(address _treasury) external onlyRole(ADMIN_ROLE) {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function getBattle(uint256 battleId) external view returns (BattleData memory) {
        return _battles[battleId];
    }

    function getMarketMakerIncentive(uint256 battleId) public view returns (uint256) {
        (bool yes, uint256 prizePool) = _checkBothSidesFilled(battleId);
        if (!yes) {
            return 0;
        }
        uint256 limit = 10000; // -> 100%
        return ((prizePool * marketMakerIncentive) / limit);
    }

    function getPlatformFee(uint256 battleId) public view returns (uint256) {
        (bool yes, uint256 prizePool) = _checkBothSidesFilled(battleId);
        if (!yes) {
            return 0;
        }
        uint256 limit = 10000; // -> 100%
        return ((prizePool * platformFee) / limit);
    }

    function getPrizePoolAndOdds(uint256 battleId)
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

        option0Odd = battle.option0PrizePool == 0 ? 0 : lot / battle.option0PrizePool;
        option1Odd = battle.option1PrizePool == 0 ? 0 : lot / battle.option1PrizePool;
    }

    function getPayout(address who, uint256 battleId) public view returns (uint256) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][battleId];
        BattleData memory battleMem = _battles[battleId];

        if (battleMem.winOption == BattleOption.Default || battleMem.winOption != predictionMem.option) {
            return 0;
        }

        (, uint256 option0Odd, uint256 option1Odd) = getPrizePoolAndOdds(battleId);

        uint256 limit = 10000; // -> 100%
        uint256 scale = 1e18;

        if (predictionMem.option == BattleOption.Option0) {
            return (
                (
                    (
                        (option0Odd * predictionMem.amount)
                            * (limit - (uint256(marketMakerIncentive) + uint256(platformFee)))
                    ) / limit
                ) / scale
            );
        }
        return (
            (
                ((option1Odd * predictionMem.amount) * (limit - (uint256(marketMakerIncentive) + uint256(platformFee))))
                    / limit
            ) / scale
        );
    }

    function getUserPrediction(address user, uint256 battleId) external view returns (UserPrediction memory) {
        return _userToIdToPrediction[user][battleId];
    }

    function generateHash(BattleManifest calldata manifest, uint64 startTimestamp)
        public
        view
        returns (bytes32 hash, bool isActive)
    {
        BattleTimeline memory _timeline = timeline;
        require(startTimestamp < uint64(block.timestamp) + _timeline.maxIntervals, "Error: Too far in the future");

        // Sort from smallest to biggest
        (string memory a, string memory b) = keccak256(abi.encodePacked(manifest.option0Id))
            < keccak256(abi.encodePacked(manifest.option1Id))
            ? (manifest.option0Id, manifest.option1Id)
            : (manifest.option1Id, manifest.option0Id);
        hash = keccak256(abi.encodePacked(a, b, manifest.battleType));

        uint64 lastSchedule = _schedules[hash];

        if (
            (lastSchedule < startTimestamp && lastSchedule + _timeline.interval > startTimestamp)
                || (startTimestamp < lastSchedule && startTimestamp + _timeline.interval > lastSchedule)
                || lastSchedule == startTimestamp
        ) {
            isActive = true;
        }
    }

    function getRefund(address who, uint256 battleId) public view returns (uint256) {
        BattleData memory battleMem = _battles[battleId];

        if (!battleMem.isRefundable) {
            return 0;
        }

        return _userToIdToPrediction[who][battleId].amount;
    }

    function mondayUtil() external view returns (uint64 nextMondayTimestamp, uint64 mondayAfterNextTimestamp) {
        return TimeHelper._nextTwoMondays(INIT_MONDAY);
    }

    function _makePrediction(
        address who,
        uint256 battleId,
        BattleOption option,
        uint256 amount,
        uint256[] memory ticketIds
    ) private openWindow(battleId) validParams(option, amount) onlyRole(RELAYER_ROLE) {
        BattleData storage battle = _battles[battleId];
        require(_userToIdToPrediction[who][battleId].amount == 0, "Update entries instead");

        _userToIdToPrediction[who][battleId] = UserPrediction({option: option, amount: amount, isClosed: false});

        unchecked {
            if (option == BattleOption.Option0) {
                battle.option0Count++;
                battle.option0PrizePool += amount;
            } else {
                battle.option1Count++;
                battle.option1PrizePool += amount;
            }
        }

        emit MakePrediction(who, battleId, amount, option, ticketIds);
    }

    function _createBattle(
        address creator,
        BattleManifest calldata manifest,
        BattleOption option,
        uint256 amount,
        bool useNextWindow,
        uint256[] memory ticketIds
    ) private validParams(option, amount) onlyRole(RELAYER_ROLE) {
        (uint64 nextMonday, uint64 followingMonday) = TimeHelper._nextTwoMondays(INIT_MONDAY);
        uint64 startTimestamp = useNextWindow ? nextMonday : followingMonday;
        BattleTimeline memory _timeline = timeline;
        require(_timeline.minTimeForBets <= startTimestamp - uint64(block.timestamp), "Limited betting time");

        (bytes32 hash, bool active) = generateHash(manifest, startTimestamp);
        require(!active, "Error: Manifest is already active");

        _schedules[hash] = startTimestamp;

        uint256 id = battleIds;
        unchecked {
            battleIds++;
        }

        (uint256 option0PrizePool, uint256 option1PrizePool, uint256 option0Count, uint256 option1Count) =
            option == BattleOption.Option0 ? (amount, uint256(0), 1, 0) : (uint256(0), amount, 0, 1);

        _battles[id] = BattleData({
            creator: creator,
            hasClaimedIncentive: false,
            hasClaimedPlatformFee: false,
            manifest: manifest,
            option0PrizePool: option0PrizePool,
            option1PrizePool: option1PrizePool,
            option0Count: option0Count,
            option1Count: option1Count,
            startTimestamp: startTimestamp,
            closeTimestamp: startTimestamp + _timeline.interval,
            aPIRequestId: 0,
            isRefundable: false,
            winOption: BattleOption.Default
        });

        emit CreateBattle(creator, manifest.battleType, id, hash, manifest);

        _userToIdToPrediction[creator][id] = UserPrediction({option: option, amount: amount, isClosed: false});

        emit MakePrediction(creator, id, amount, option, ticketIds);
    }

    function _ticketBurner(uint256[] memory ticketIds, address who) private returns (uint256) {
        return ticket.burnTickets(ticketIds, who);
    }

    function _feeAndIncentiveChecks(BattleOption option, uint256 incentive) private pure {
        require(option != BattleOption.Default, "Error: Unresolved battle");
        require(incentive != 0, "Error: Nothing to claim");
    }

    function _dummyChainlinkFunc(uint64 start, uint64 close) private view returns (BattleOption, uint256) {
        uint256 aPIRequestId = close - start + block.timestamp;
        if (uint64(block.timestamp) < close) {
            return (BattleOption.Default, aPIRequestId);
        }
        if ((close - start) % 2 == 0) {
            return (BattleOption.Option0, aPIRequestId);
        }
        return (BattleOption.Option1, aPIRequestId);
    }

    function _checkBothSidesFilled(uint256 battleId) private view returns (bool, uint256) {
        (uint256 prizePool, uint256 option0Odd, uint256 option1Odd) = getPrizePoolAndOdds(battleId);

        if (option0Odd == 0 || option1Odd == 0) {
            return (false, prizePool);
        }
        return (true, prizePool);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
