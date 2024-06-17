// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC1155Supply, ERC1155} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBattlesTicket} from "./interfaces/IBattlesTicket.sol";

contract BattlesTicket is
    AccessControlEnumerable,
    ERC1155Supply,
    IBattlesTicket,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;

    string public name;
    string public symbol;

    uint256 private _currentID;
    uint64 public minExpiry;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BATTLE_ROLE = keccak256("BATTLE_ROLE");

    mapping(uint256 => Ticket) _tickets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _usdc,
        address _controller,
        address _admin,
        uint64 _minExpiry
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;

        usdc = IERC20(_usdc);
        minExpiry = _minExpiry;

        _grantRole(DEFAULT_ADMIN_ROLE, _controller);
        _grantRole(ADMIN_ROLE, _admin);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BATTLE_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setMinExpiry(uint64 _minExpiry) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "UNAUTHORIZED_CALLER");
        minExpiry = _minExpiry;
        emit SetMinExpiry(_minExpiry);
    }

    function mintTickets(
        address issuer,
        address[] calldata recipients,
        uint256[] calldata ticketPrices,
        uint64[] calldata ticketExpirations
    ) external nonReentrant returns (uint256[] memory ids) {
        uint256 length = recipients.length;
        require(
            length == ticketPrices.length && length == ticketExpirations.length,
            "Unequal array length"
        );
        ids = new uint256[](length);
        uint256 currentID = _currentID;
        uint256 totalCost;
        uint256 id;
        address recipient;
        uint256 ticketPrice;
        uint64 ticketExpiration;
        uint64 minExpiry_ = minExpiry;
        uint64 expirationDate;
        for (uint256 i; i < length; ) {
            currentID++;
            ids[i] = currentID;
            id = ids[i];
            recipient = recipients[i];
            require(recipient != address(0), "Null address for recipient");
            ticketPrice = ticketPrices[i];
            require(ticketPrice != 0, "Null value for ticketPrice");
            ticketExpiration = ticketExpirations[i];
            require(
                ticketExpiration >= minExpiry_,
                "Min expiry for ticketExpiration not met"
            );
            totalCost += ticketPrice;
            _mint(recipient, id, 1, "");
            expirationDate = uint64(block.timestamp) + ticketExpiration;
            _tickets[id] = Ticket({
                amountLocked: ticketPrice,
                expirationDate: expirationDate,
                issuer: issuer,
                holder: recipient
            });
            emit TicketMinted(
                id,
                issuer,
                recipient,
                ticketPrice,
                expirationDate
            );
            unchecked {
                ++i;
            }
        }

        usdc.safeTransferFrom(issuer, address(this), totalCost);
        _currentID = currentID;
    }

    function burnTickets(
        uint256[] calldata ids,
        address who
    ) external nonReentrant returns (uint256 totalValue) {
        uint256 length = ids.length;
        uint256 id;
        Ticket memory ticket;
        for (uint256 i; i < length; ) {
            id = ids[i];
            ticket = _tickets[id];
            require(ticket.amountLocked > 0, "Nonexistent token");
            if (uint64(block.timestamp) < ticket.expirationDate) {
                require(
                    hasRole(BATTLE_ROLE, _msgSender()),
                    "UNAUTHORIZED_CALLER"
                );
                require(who == ticket.holder, "Incorrect holder");
                emit TicketClosed(id, ticket.holder, ticket.amountLocked, true);
            } else {
                require(ticket.issuer == _msgSender(), "UNAUTHORIZED_CALLER");
                emit TicketClosed(
                    id,
                    ticket.holder,
                    ticket.amountLocked,
                    false
                );
            }
            totalValue += ticket.amountLocked;
            _burn(ticket.holder, id, 1);
            delete _tickets[id];
            unchecked {
                ++i;
            }
        }
        usdc.safeTransfer(_msgSender(), totalValue);
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override(ERC1155) {
        revert("Non-transferrable token");
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override(ERC1155) {
        revert("Non-transferrable token");
    }

    function setApprovalForAll(address, bool) public pure override(ERC1155) {
        revert("Non-transferrable token");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getTicket(uint256 id) external view returns (Ticket memory) {
        return _tickets[id];
    }
}
