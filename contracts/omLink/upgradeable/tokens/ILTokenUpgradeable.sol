// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILTokenUpgradeable is IERC20Upgradeable {
    function masterMint(address account, uint256 amount) external returns (bool);
    function masterBurnFrom(address account, uint256 amount) external returns (bool);
    function mintTo (address account, uint256 amount) external returns (bool);
    function burnFrom (address account, uint256 amount) external returns (bool);

    event TokenMinted(address account, uint256 amount);
    event TokenBurned(address account, uint256 amount);
}