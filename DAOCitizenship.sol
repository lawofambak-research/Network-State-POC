//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a proof of concept token contract that
 * represents a citizenship for a user. The add-on
 * is a registration date (mint date). This token
 * is non-transferable as a real citizenship is
 * also non-transferable. However, this comes with
 * a function to destroy one's citizenship.
 * NOTE: Not production ready as citizenship could
 * include various of other factors just like in real
 * life.
 */

contract DAOCitizenship {
    // Token name
    string private _tokenName = "Citizenship";

    // Token symbol
    string private _tokenSymbol = "CTZ";

    // Mapping from citizen ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token/citizenship count
    mapping(address => uint256) private _balances;

    // Mapping citizen address to registration date
    mapping(address => uint256) private _registrationDate;

    /**
     * @dev Emitted when `citizenId` token is minted.
     */
    event Mint(address indexed to, uint256 indexed citizenId);

    /**
     * @dev Emitted when `citizenId` token is burned.
     */
    event Burn(address indexed owner, uint256 indexed citizenId);

    /**
     * @dev Returns token/citizenship count of owner.
     */
    function balanceOf(address _citizen) public view returns (uint256) {
        require(_citizen != address(0), "Address zero is not a valid citizen");
        return _balances[_citizen];
    }

    /**
     * @dev Returns address of owner from citizen ID.
     */
    function ownerOf(uint256 _citizenId) public view returns (address) {
        address owner = _owners[_citizenId];
        require(owner != address(0), "Invalid citizen ID");
        return owner;
    }

    /**
     * @dev Returns the citizenship name.
     */
    function tokenName() public view returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev Returns the citizenship symbol.
     */
    function tokenSymbol() public view returns (string memory) {
        return _tokenSymbol;
    }

    /**
     * @dev Returns the citizen registration date.
     *
     * Requirements:
     *
     * - `_citizen` must be registered.
     */
    function registrationDate(address _citizen) public view returns (uint256) {
        require(_citizen != address(0), "Address zero is not a valid citizen");
        uint256 registrationDate_ = _registrationDate[_citizen];
        require(registrationDate_ != 0, "Not registered as citizen");
        return registrationDate_;
    }

    /**
     * @dev Returns whether `citizenId` exists.
     *
     * Tokens/citizenships can be managed by their owner.
     *
     * Tokens/citizenships start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 _citizenId) internal view returns (bool) {
        return _owners[_citizenId] != address(0);
    }

    /**
     * @dev Mints `citizenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `citizenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Mint} event.
     */
    function _mint(address _to, uint256 _citizenId) internal {
        require(_to != address(0), "Mint to the zero address");
        require(!_exists(_citizenId), "Citizen ID already minted");

        _balances[_to] += 1;
        _owners[_citizenId] = _to;
        _registrationDate[_to] = block.timestamp;

        emit Mint(_to, _citizenId);
    }

    /**
     * @dev Destroys `citizenId`.
     *
     * Requirements:
     *
     * - `citizenId` must exist.
     *
     * Emits a {Burn} event.
     */
    function _burn(uint256 _citizenId) internal {
        address citizen = ownerOf(_citizenId);

        _balances[citizen] -= 1;
        delete _owners[_citizenId];
        delete _registrationDate[citizen];

        emit Burn(citizen, _citizenId);
    }
}
