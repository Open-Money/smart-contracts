// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Guarded is AccessControl{

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    address private _owner;
    bool private _paused;

    modifier onlyOwner ()
    {
        require(_owner == _msgSender(), "Guard: not owner");
        _;
    }

    modifier onlyAdmin ()
    {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Guard: not admin");
        _;
    }

    modifier onlyMinter () {
        require(hasRole(MINTER_ROLE, _msgSender()), "Guard: not minter");
        _;
    }

    modifier onlyBurner () {
        require(hasRole(BURNER_ROLE, _msgSender()),"Guard: not burner");
        _;
    }

    modifier nonPaused () {
        require(!_paused, "Guard: contract paused");
        _;
    }

    modifier paused () {
        require(_paused, "Guard: contract is not paused");
        _;
    }

    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _owner = _msgSender();
        _paused = false;
    }

    function pause() public onlyAdmin nonPaused returns (bool) {
        _paused = true;
        emit ContractPaused(block.number,_msgSender());
        return true;
    }

    function unpause() public onlyAdmin paused returns (bool) {
        _paused = false;
        emit ContractUnpaused(block.number,_msgSender());
        return true;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function transferOwner (address owner) public onlyOwner returns (bool) {
        grantRole(DEFAULT_ADMIN_ROLE, owner);
        grantRole(ADMIN_ROLE, owner);

        revokeRole(DEFAULT_ADMIN_ROLE,_owner);
        revokeRole(ADMIN_ROLE,_owner);

        emit OwnerChanged(_owner,owner);

        _owner = owner;

        return true;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyOwner {
        _setRoleAdmin(role,adminRole);
    }
    
    event ContractPaused(uint256 blockHeight, address admin);
    event ContractUnpaused(uint256 blockHeight, address admin);
    event OwnerChanged(address previousOwner, address currentOwner);

}