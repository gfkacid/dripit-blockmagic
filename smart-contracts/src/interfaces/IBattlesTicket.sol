// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IBattlesTicket {
    struct Ticket {
        address issuer;
        uint256 amountLocked;
        address holder;
        uint64 expirationDate;
    }
    event TicketMinted(
        uint256 indexed id,
        address indexed issuer,
        address indexed holder,
        uint256 ticketPrice,
        uint64 expirationDate
    );

    event TicketClosed(
        uint256 indexed id,
        address indexed holder,
        uint256 ticketPrice,
        bool indexed isUsed
    );

    event SetMinExpiry(uint256 minExpiry);

    function setMinExpiry(uint64 _minExpiry) external;

    function mintTickets(
        address issuer,
        address[] calldata recipients,
        uint256[] calldata ticketPrices,
        uint64[] calldata ticketExpirations
    ) external returns (uint256[] memory ids);

    function burnTickets(
        uint256[] calldata ids,
        address who
    ) external returns (uint256 totalValue);

    function getTicket(uint256 id) external view returns (Ticket memory);
}
