// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library TimeHelper {
    uint64 constant ONE_WEEK = 1 weeks;

    function _nextTwoMondays(uint64 init_monday) internal view returns (uint64 nextMonday, uint64 mondayAfterNext) {
        nextMonday = _nextMondayTimestamp(uint64(block.timestamp), init_monday);
        uint64 one_week = ONE_WEEK;
        mondayAfterNext = nextMonday + one_week;
    }

    function _nextMondayTimestamp(uint64 timestamp, uint64 init_monday) private pure returns (uint64) {
        if (timestamp <= init_monday) {
            return init_monday;
        } else {
            uint64 one_week = ONE_WEEK;
            uint64 weeksSinceInitMonday = ((timestamp - init_monday) / one_week) + 1;
            return init_monday + (weeksSinceInitMonday * one_week);
        }
    }
}
