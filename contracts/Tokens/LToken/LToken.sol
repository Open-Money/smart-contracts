// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "../utils/Guarded.sol";
import "../utils/TokenRecover.sol";
import "../utils/Blacklistable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILToken.sol";


contract LToken is Guarded, TokenRecover, Blacklistable, ERC20, ILToken {

    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) TokenRecover() ERC20(name, symbol) {
        _decimals = decimals_;
        blacklister = msg.sender;
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

    function transfer(address recipient, uint256 amount) public override(ERC20, IERC20) nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender)),"LToken: receiver or sender blacklisted");
        return ERC20.transfer(recipient,amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20, IERC20) nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender) && !isBlacklisted(sender)),"LToken: receiver or sender blacklisted");
        return ERC20.transferFrom(sender,recipient,amount);
    }

}