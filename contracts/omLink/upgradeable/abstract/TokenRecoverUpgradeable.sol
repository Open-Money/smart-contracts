// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./GuardedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract TokenRecoverUpgradeable is Initializable, GuardedUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokenRecover_init() public initializer {
        __Guarded_init();
        __TokenRecover_init_unchained();
    }

    function __TokenRecover_init_unchained() public initializer {
        
    }

    function recoverERC20(address token, address recipient, uint256 amount) public onlyOwner() returns (bool)
    {
        IERC20Upgradeable(token).safeTransfer(recipient,amount);
        emit ERC20Recovered(token,recipient,amount);
        return true;
    }

    function recoverEth (address recipient) public onlyOwner() returns (bool){
        emit EthRecovered(recipient,address(this).balance);
        payable(recipient).transfer(address(this).balance);
        return true;
    }

    event ERC20Recovered(address token, address recipient, uint256 amount);
    event EthRecovered(address recipient, uint256 amount);

    uint256[50] private __gap;
}