// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Guarded.sol";

abstract contract TokenRecover is Guarded {

    using SafeERC20 for IERC20;

    function recoverERC20(address token, address recipient, uint256 amount) public onlyOwner() returns (bool)
    {
        IERC20(token).safeTransfer(recipient,amount);
        emit ERC20Recovered(token,recipient,amount);
        return true;
    }

    event ERC20Recovered(address token, address recipient, uint256 amount);
}