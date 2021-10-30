// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

/**
 * @title omLink tracking contract 
 *
 * @author Osman Kuzucu - osman@openmoney.com.tr
 * https://github.com/nithronium
 * 
 * @dev this contract tracks the nonces and eliminates duplicate minting
 */
contract Tracked {

    /** 
     * 
     * @dev struct for a given nonce with `token` and `nonce`
     *
     */
    struct nonceDataStruct {
        bool _isUsed;
        uint256 _inBlock;
    }

    /** 
     * 
     * @dev struct for the nonces per token address
     *
     */
    struct contractTrackerStruct {
        uint256 _biggestWithdrawNonce;
        uint256 _depositNonce;
        mapping (uint256 => nonceDataStruct) _nonces;
    }

    mapping (address => contractTrackerStruct) internal _tracker;

    /**
     * @dev modifier that checks whethether a nonce is used or not 
     * 
     * @param token token contract address
     * @param nonce nonce to query
     *
     */
    modifier nonUsedNonce(address token, uint nonce) {
        require(_tracker[token]._nonces[nonce]._isUsed == false, "Tracker: nonce already used");
        _;
    }

    /**
     * @dev function that marks a nonce as used
     *
     * emits {NonceUsed} event
     * 
     * @param token token contract address
     * @param nonce the nonce to be marked as used
     * 
     */
    function useNonce(address token, uint nonce) internal nonUsedNonce(token,nonce) {
        _tracker[token]._nonces[nonce]._isUsed = true;
        _tracker[token]._nonces[nonce]._inBlock = block.number;

        /**
         * Sets the contract's biggest withdraw nonce 
         * if current withdraw nonce is the known biggest one
         * 
         * this is for information purposes only
         */
        if(nonce > _tracker[token]._biggestWithdrawNonce) {
            _tracker[token]._biggestWithdrawNonce = nonce;
        }

        emit NonceUsed(token,nonce,block.number);
    }

    /**
     * @dev gets information about the given withdrawal nonce 
     * of the any given token
     *
     * @param token token contract address
     * @param nonce nonce to be queried
     * 
     * @return (bool,uint256) 
     * 
     */
    function getNonceData(address token, uint256 nonce) public view returns (bool,uint256) {
        return(_tracker[token]._nonces[nonce]._isUsed,_tracker[token]._nonces[nonce]._inBlock);
    }

    /**
     * @dev checks if a withdraw nonce has been used before
     * 
     * @param token token contract address
     * @param nonce nonce to be queried
     * 
     * @return bool
     *
     */
    function isUsedNonce(address token, uint256 nonce) public view returns (bool) {
        return(_tracker[token]._nonces[nonce]._isUsed);
    }

    /**
     * 
     * @dev increments the deposit nonce of the given token
     * 
     * @param token token contract address
     * 
     */
    function depositNonce(address token) internal {
        _tracker[token]._depositNonce+=1;
    }

    /**
     * 
     * @dev gets the current deposit nonce of the given token
     *
     * @param token token contract address
     * 
     * @return uint256
     */
    function getDepositNonce (address token) public view returns (uint256) {
        return _tracker[token]._depositNonce;
    }

    event NonceUsed(address token, uint256 nonce, uint256 blockNumber);
}