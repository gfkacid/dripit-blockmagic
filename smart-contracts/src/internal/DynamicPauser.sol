// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract DynamicPauser {
    /**
     * @dev mapping function signature to bool
     */
    mapping(bytes4 => bool) _pauses;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account, bytes4 indexed selector);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account, bytes4 indexed selector);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause(bytes4 selector);

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause(bytes4 selector);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(bytes4 selector) {
        _requireNotPaused(selector);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(bytes4 selector) {
        _requirePaused(selector);
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(bytes4 selector) public view virtual returns (bool) {
        return _pauses[selector];
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused(bytes4 selector) internal view virtual {
        if (paused(selector)) {
            revert EnforcedPause(selector);
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused(bytes4 selector) internal view virtual {
        if (!paused(selector)) {
            revert ExpectedPause(selector);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(bytes4 selector) internal virtual whenNotPaused(selector) {
        _pauses[selector] = true;
        emit Paused(msg.sender, selector);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(bytes4 selector) internal virtual whenPaused(selector) {
        _pauses[selector] = false;
        emit Unpaused(msg.sender, selector);
    }
}
