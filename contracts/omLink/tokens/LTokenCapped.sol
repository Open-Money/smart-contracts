// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import "../abstract/Guarded.sol";
import "../abstract/TokenRecover.sol";
import "../abstract/Blacklistable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";


contract LTokenCapped is Guarded, TokenRecover, Blacklistable, ERC20Capped {

    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint256 cap_, uint8 decimals_) TokenRecover() ERC20(name, symbol) ERC20Capped(cap_) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function masterMint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account,amount);
        emit TokenMinted(account,amount);
        return true;
    }

    function masterBurnFrom(address account, uint256 amount) public onlyOwner returns (bool) {
        _burn(account,amount);
        emit TokenBurned(account,amount);
        return true;
    }

    function mintTo (address account, uint256 amount) public onlyMinter nonPaused notBlacklisted(account) returns (bool) {
        _mint(account,amount);
        emit TokenMinted(account,amount);
        return true;
    }

    function burnFrom (address account, uint256 amount) public nonPaused returns (bool) {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
        emit TokenBurned(account,amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender)),"LToken: receiver or sender blacklisted");
        return ERC20.transfer(recipient,amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonPaused returns (bool) {
        require((!isBlacklisted(recipient) && !isBlacklisted(msg.sender) && !isBlacklisted(sender)),"LToken: receiver or sender blacklisted");
        return ERC20.transferFrom(sender,recipient,amount);
    }

    event TokenMinted(address account, uint256 amount);
    event TokenBurned(address account, uint256 amount);
}