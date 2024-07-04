// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBattlesTicket} from "./interfaces/IBattlesTicket.sol";

contract BattlesTicket is
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721URIStorage,
    IBattlesTicket,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    uint256 private _currentID;
    string _uri;
    uint64 public minExpiry;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BATTLE_ROLE = keccak256("BATTLE_ROLE");

    mapping(uint256 => Ticket) _tickets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        address _token,
        address _controller,
        address _admin,
        uint64 _minExpiry
    ) ERC721(_name, _symbol) {
        _uri = uri;

        token = IERC20(_token);
        minExpiry = _minExpiry;

        _grantRole(DEFAULT_ADMIN_ROLE, _controller);
        _grantRole(ADMIN_ROLE, _admin);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BATTLE_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "UNAUTHORIZED_CALLER");
        _;
    }

    function setBaseURI(string memory baseURI) external onlyAdmin {
        _uri = baseURI;
        emit BaseURIUpdate(baseURI);
    }

    function setMinExpiry(uint64 _minExpiry) external onlyAdmin {
        minExpiry = _minExpiry;
        emit SetMinExpiry(_minExpiry);
    }

    function mintTickets(
        address issuer,
        address[] memory recipients,
        uint256[] memory ticketPrices,
        uint64[] memory ticketExpirations
    ) external nonReentrant returns (uint256[] memory ids) {
        uint256 length = recipients.length;
        require(length == ticketPrices.length && length == ticketExpirations.length, "Unequal array length");
        ids = new uint256[](length);
        uint256 currentID = _currentID;
        uint256 totalCost;
        uint256 id;
        address recipient;
        uint256 ticketPrice;
        uint64 ticketExpiration;
        uint64 minExpiry_ = minExpiry;
        uint64 expirationDate;
        for (uint256 i; i < length;) {
            currentID++;
            ids[i] = currentID;
            id = ids[i];
            recipient = recipients[i];
            require(recipient != address(0), "Null address for recipient");
            ticketPrice = ticketPrices[i];
            require(ticketPrice != 0, "Null value for ticketPrice");
            ticketExpiration = ticketExpirations[i];
            require(ticketExpiration >= minExpiry_, "Min expiry for ticketExpiration not met");
            totalCost = totalCost + ticketPrice;
            _mint(recipient, id);
            expirationDate = uint64(block.timestamp) + ticketExpiration;
            emit TicketMinted(id, issuer, recipient, ticketPrice, expirationDate);
            _tickets[id] =
                Ticket({amountLocked: ticketPrice, expirationDate: expirationDate, issuer: issuer, holder: recipient});
            unchecked {
                ++i;
            }
        }

        token.safeTransferFrom(issuer, address(this), totalCost);
        _currentID = currentID;
    }

    function burnTickets(uint256[] calldata ids, address who) external nonReentrant returns (uint256 totalValue) {
        uint256 length = ids.length;
        uint256 id;
        Ticket memory ticket;
        for (uint256 i; i < length;) {
            id = ids[i];
            ticket = _tickets[id];
            require(ticket.amountLocked > 0, "Insufficient token");
            if (uint64(block.timestamp) < ticket.expirationDate) {
                require(hasRole(BATTLE_ROLE, _msgSender()), "UNAUTHORIZED_CALLER");
                require(who == ticket.holder, "Incorrect holder");
                emit TicketClosed(id, ticket.holder, ticket.amountLocked, true);
            } else {
                require(ticket.issuer == _msgSender(), "UNAUTHORIZED_CALLER");
                emit TicketClosed(id, ticket.holder, ticket.amountLocked, false);
            }
            totalValue = totalValue + ticket.amountLocked;
            _burn(id);
            delete _tickets[id];
            unchecked {
                ++i;
            }
        }
        token.safeTransfer(_msgSender(), totalValue);
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert("Non-transferrable token");
    }

    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("Non-transferrable token");
    }

    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert("Non-transferrable token");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function getTicket(uint256 id) external view returns (Ticket memory) {
        return _tickets[id];
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}
