// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimeLocked {

    address private _tokenAddress;
    address[] private _signers;
    address private _owner;
    address private _transferTo;
    uint256 private _amount;
    uint private _sigCount;
    mapping (address => bool) _hasSigned;

    modifier onlyOwner {
        require(_owner == msg.sender,"You must be owner");
        _;
    }

    modifier onlySigner {
        uint k = 0;
        for (uint i=0; i<_signers.length; i++) {
            if(_signers[i] == msg.sender) {
                k++;
            }
        }
        require(k == 1, "You are not a signer");
        _;
    }

    modifier onlyOnce {
        require(!_hasSigned[msg.sender],"You already signed");
        _;
    }

    modifier onlyAfter {
        require(block.timestamp > 1704056400, "Time hasn't arrived yet");
        _;
    }

    constructor(address[] memory signers) {
        _owner = msg.sender;
        uint arrayLength = signers.length;
        for (uint i=0; i<arrayLength; i++) {
            _signers[i] = signers[i];
        }
    }

    function getSigners (uint id) public view returns (address) {
        return _signers[id];
    }

    function getSignersCount () public view returns (uint) {
        return _signers.length;
    }

    function initializeTransfer (address transferTo, address tokenAddress, uint256 amount) public onlyOwner {
        _transferTo = transferTo;
        _tokenAddress = tokenAddress;
        _amount = amount;
        _sigCount = 0;
    }

    function approveTransfer () public onlySigner onlyOnce {
        _sigCount++;
    }

    function finalizeTransfer () public onlyOwner onlyAfter {
        require(2*_sigCount > _signers.length, "Not enough signers");
        Token(_tokenAddress).transfer(_transferTo, _amount);
    }

}