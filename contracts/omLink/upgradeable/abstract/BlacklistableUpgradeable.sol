// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./GuardedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract BlacklistableUpgradeable is Initializable, GuardedUpgradeable {
    
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

    function __Blacklistable_init() public initializer {
        __Guarded_init();
        __Blacklistable_init_unchained();
    }

    function __Blacklistable_init_unchained() public initializer {
        
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

    uint256[48] private __gap;
}