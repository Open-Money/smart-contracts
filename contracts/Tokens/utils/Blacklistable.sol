// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "./Guarded.sol";

contract Blacklistable is Guarded {
    address public blacklister;

    mapping(address => bool) internal blacklisted;

    modifier onlyBlacklister() {
        require(blacklister == _msgSender(),"Blacklistable: non-blacklister");
        _;
    }

    modifier notBlacklisted(address _account) {
        require(!blacklisted[_account],"Blacklistable: account is blacklisted");
        _;
    }

    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) external onlyOwner {
        require(
            _newBlacklister != address(0),
            "Blacklistable: new blacklister is the zero address"
        );
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);
}