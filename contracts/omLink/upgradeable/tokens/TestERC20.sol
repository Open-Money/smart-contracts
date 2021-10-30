// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract TestERC20 is ERC20Upgradeable {

    constructor (string memory name_, string memory symbol_) {
        __ERC20_init(name_,symbol_);
    }
}