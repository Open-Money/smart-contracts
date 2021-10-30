// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "../abstract/Guarded.sol";
import "../abstract/Blacklistable.sol";
import "../abstract/TokenRecover.sol";

contract Fiber is Guarded, Blacklistable, TokenRecover {

    mapping(address => bool) public _supportedTokens;
    mapping(address => bool) public _isLinkToken;

    mapping (address => bool) internal _verifiedSigners;

    /**
     * @dev modifier that checks whether the link token is supported or not
     */
    modifier onlySupportedToken(address contractAddress) {
        require(isSupportedToken(contractAddress),"Fiber: token not supported");
        _;
    }

    /** 
     * @dev modifier that checks the signature is from a verified signer
     */
    modifier onlyVerifiedSigner(address signer) {
        require(_verifiedSigners[signer] == true,"Tracked:signer is not verified");
        _;
    }

    function isVerifiedSigner (address signer) public view returns (bool){
        return _verifiedSigners[signer];
    }

    function isSupportedToken (address contractAddress) public view returns (bool)
    {
        return _supportedTokens[contractAddress];
    }

    /** 
     * @dev function tat adds a new verified signer
     * called only by the owner
     */
    function addVerifiedSigner (address signer) public onlyOwner() returns (bool)
    {
        _verifiedSigners[signer] = true;
        return true;
    }

    /** 
     * @dev function that removes a verified signer
     * called only by the owner
     */
    function removeVerifiedSigner (address signer) public onlyOwner() returns (bool) {
        _verifiedSigners[signer] = false;
        return true;
    }

    /** 
     * @dev function that checks whether the token is LinkToken or not
     */
    function isLinkToken (address contractAddress) public view returns (bool) {
        return _isLinkToken[contractAddress];
    }

    /**
     * @dev function that adds supported token
     */
    function addSupportedToken (address contractAddress, bool isLToken) public onlyOwner returns (bool)
    {
        emit SupportedTokenAdded(contractAddress,isLToken, msg.sender);
        return _addSupportedToken(contractAddress,isLToken);
    }

    /**
     * @dev function that removes supported token
     */
    function removeSupportedToken (address contractAddress) public onlyOwner returns (bool)
    {
        emit SupportedTokenRemoved(contractAddress, msg.sender);
        return _removeSupportedToken (contractAddress);
    }

    /**
     * @dev internal function that adds supported token
     */
    function _addSupportedToken (address contractAddress,bool isLToken) internal virtual returns (bool)
    {
        _supportedTokens[contractAddress] = true;
        _isLinkToken[contractAddress] = isLToken;
        return true;
    }

    /**
     * @dev internal function that removes supported token
     */
    function _removeSupportedToken (address contractAddress) internal virtual returns (bool)
    {
        _supportedTokens[contractAddress] = false;
        _isLinkToken[contractAddress] = false;
        return true;
    }

    event SupportedTokenAdded(address contractAddress, bool isLToken, address admin);
    event SupportedTokenRemoved(address contractAddress, address admin);

}