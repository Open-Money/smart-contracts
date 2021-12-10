// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILToken is IERC20 {
    function masterMint(address account, uint256 amount) external returns (bool);
    function mintTo (address account, uint256 amount) external returns (bool);
    function burnFrom (address account, uint256 amount) external returns (bool);

    event TokenMinted(address account, uint256 amount);
    event TokenBurned(address account, uint256 amount);
}