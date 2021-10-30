// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../abstract/GuardedUpgradeable.sol";
import "../abstract/BlacklistableUpgradeable.sol";
import "../abstract/TokenRecoverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ILTokenUpgradeable.sol";

contract LTokenUpgradeable is Initializable, GuardedUpgradeable,TokenRecoverUpgradeable, BlacklistableUpgradeable, ERC20Upgradeable, ILTokenUpgradeable {
    uint8 private _decimals;

    function __LToken_init(string memory name_, string memory symbol_, uint8 decimals_) public initializer {
        __Guarded_init();
        __TokenRecover_init();
        __Blacklistable_init();
        __ERC20_init(name_,symbol_);
        __LToken_init_unchained(decimals_);
    }

    function __LToken_init_unchained(uint8 decimals_) public initializer{
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function masterMint(address account, uint256 amount) public override onlyOwner returns (bool) {
        _mint(account,amount);
        emit TokenMinted(account,amount);
        return true;
    }

    function masterBurnFrom(address account, uint256 amount) public override onlyOwner returns (bool) {
        _burn(account,amount);
        emit TokenBurned(account,amount);
        return true;
    }

    function mintTo (address account, uint256 amount) public override onlyMinter nonPaused notBlacklisted(account) returns (bool) {
        _mint(account,amount);
        emit TokenMinted(account,amount);
        return true;
    }

    function burnFrom (address account, uint256 amount) public override onlyBurner nonPaused returns (bool) {
        _burn(account,amount);
        emit TokenBurned(account,amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override(ERC20Upgradeable, IERC20Upgradeable) nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender)),"LToken: receiver or sender blacklisted");
        return ERC20Upgradeable.transfer(recipient,amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20Upgradeable, IERC20Upgradeable) nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender) && !isBlacklisted(sender)),"LToken: receiver or sender blacklisted");
        return ERC20Upgradeable.transferFrom(sender,recipient,amount);
    }

    uint256[49] private __gap;

}