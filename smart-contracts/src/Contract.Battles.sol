// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20 ^0.8.20;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// src/Battles.sol

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

contract Battles is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public battleIds;
    uint256 public minAmount;
    uint64 public constant DURATION = 1 weeks;
    uint64 public constant FUTURE_LIMIT = 2 weeks;
    uint8 public constant MARKET_MAKER_INCENTIVE = 100; // 1% == 100

    // user => battleId => UserPrediction
    mapping(address => mapping(uint256 => UserPrediction)) _userToIdToPrediction;

    // battleId => BattleData
    mapping(uint256 => BattleData) _battles;

    // hash to index to stat time
    mapping(bytes32 => uint64) _schedules;

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

    constructor(
        address initialOwner,
        address _token,
        uint256 _minAmount
    ) Ownable(initialOwner) {
        token = IERC20(_token);
        minAmount = _minAmount;
    }

    modifier validParams(BattleOption option, uint256 amount) {
        require(BattleOption.Default != option, "Error: Wrong option");
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
            closeTimestamp: startTimestamp + DURATION,
            aPIRequestId: 0,
            winOption: BattleOption.Default
        });

        emit CreateBattle(creator, manifest.battleType, id, hash, manifest);
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

            if (predictionMem.amount - amount == 0) {
                prediction.isClosed = true;
            }

            unchecked {
                prediction.amount -= amount;

                if (predictionMem.option == BattleOption.Option0) {
                    battle.option0PrizePool -= amount;
                } else {
                    battle.option1PrizePool -= amount;
                }
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
        return ((prizePool * MARKET_MAKER_INCENTIVE) / limit);
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
        option0Odd = battle.option0PrizePool == 0
            ? 1 // prizePool
            : prizePool / battle.option0PrizePool;
        option1Odd = battle.option1PrizePool == 0
            ? 1 //prizePool
            : prizePool / battle.option1PrizePool;
    }

    function getPayout(
        address who,
        uint256 battleId
    ) public view returns (uint256) {
        UserPrediction memory predictionMem = _userToIdToPrediction[who][
            battleId
        ];
        BattleData memory battleMem = _battles[battleId];

        if (battleMem.winOption == BattleOption.Default) {
            return 0;
        }

        uint256 _MARKET_MAKER_INCENTIVE = uint256(MARKET_MAKER_INCENTIVE);
        (, uint256 option0Odd, uint256 option1Odd) = getPrizePoolAndOdds(
            battleId
        );

        uint256 limit = 10000; // -> 100%

        if (battleMem.winOption == predictionMem.option) {
            if (predictionMem.option == BattleOption.Option0) {
                return
                    ((option0Odd * predictionMem.amount) *
                        (limit - _MARKET_MAKER_INCENTIVE)) / limit;
            }
            return
                ((option1Odd * predictionMem.amount) *
                    (limit - _MARKET_MAKER_INCENTIVE)) / limit;
        }
        return 0;
    }

    function getPredictionByBattleId(
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
            startTimestamp < uint64(block.timestamp) + FUTURE_LIMIT,
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
            return (BattleOption.Default, aPIRequestId);
        if ((close - start) % 2 == 0)
            return (BattleOption.Option0, aPIRequestId);
        return (BattleOption.Option1, aPIRequestId);
    }
}
