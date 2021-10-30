// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import "./Guarded.sol";

/**
 * @dev Blacklist module that allows receivers or transaction senders 
 * to be blacklisted.
 */

abstract contract Blacklistable is Guarded {

    address public _blacklister;

    mapping(address => bool) internal _blacklisted;

    /**
     * @dev Modifier that checks the msg.sender for blacklisting related operations
     */
    modifier onlyBlacklister() {
        require(_blacklister == _msgSender(),"Blacklistable: account is not blacklister");
        _;
    }

    /**
     * @dev Modifier that checks the account is not blacklisted
     * @param account The address to be checked
     */
    modifier notBlacklisted(address account) {
        require(!_blacklisted[account],"Blacklistable: account is blacklisted");
        _;
    }

    /**
     * @dev Function that checks if an address is blacklisted
     * @param account The address to be checked
     * @return bool, true if account is blacklisted, false if not
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Function that blacklists an account
     * Emits {Blacklisted} event.
     * 
     * @notice can only be called by blacklister
     * @param account The address to be blacklisted
     */
    function blacklist(address account) public onlyBlacklister {
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Function that removes an address from blacklist
     * Emits {UnBlacklisted} event
     * 
     * @notice can only be called by blacklister
     * @param account to be unblacklisted
     */
    function unBlacklist(address account) public onlyBlacklister {
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    /**
     * @dev Function that updates the current blacklister account
     * Emits {BlacklisterChanged} event
     * 
     * @notice can only be called by the owner of the contract
     * @param newBlacklister address that will be the new blacklister
     */
    function updateBlacklister(address newBlacklister) external onlyOwner {
        require(
            newBlacklister != address(0),
            "Blacklistable: new blacklister is the zero address"
        );
        _blacklister = newBlacklister;
        emit BlacklisterChanged(newBlacklister);
    }

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event BlacklisterChanged(address indexed newBlacklister);
}