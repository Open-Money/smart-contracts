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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TrackedUpgradeable is Initializable {

    /** 
     * 
     * @dev struct for a given nonce with `token` and `nonce`
     *
     */
    struct nonceDataStruct {
        bool isUsed;
        uint256 inBlock;
    }

    /** 
     * 
     * @dev struct for the nonces per token address
     *
     */
    struct contractTrackerStruct {
        uint256 biggestNonce;
        uint256 depositNonce;
        mapping (uint256 => nonceDataStruct) nonce;
    }

    mapping (address => contractTrackerStruct) internal _tracker;

    modifier nonUsedNonce(address token, uint nonce) {
        require(_tracker[token].nonce[nonce].isUsed == false, "Tracker: nonce already used");
        _;
    }

    function __Tracked_init() public initializer {
        __Tracked_init_unchained();
    }

    function __Tracked_init_unchained() public initializer {
        
    }

    function useNonce(address token, uint nonce) internal nonUsedNonce(token,nonce) {
        _tracker[token].nonce[nonce].isUsed = true;
        _tracker[token].nonce[nonce].inBlock = block.number;
        if(nonce > _tracker[token].biggestNonce) {
            _tracker[token].biggestNonce = nonce;
        }
        emit NonceUsed(token,nonce,block.number);
    }

    function getNonceData(address token, uint256 nonce) public view returns (bool,uint256) {
        return(_tracker[token].nonce[nonce].isUsed,_tracker[token].nonce[nonce].inBlock);
    }

    function isUsedNonce(address token, uint256 nonce) public view returns (bool) {
        return(_tracker[token].nonce[nonce].isUsed);
    }

    function depositNonce(address token) internal {
        _tracker[token].depositNonce+=1;
    }

    function getDepositNonce (address token) public view returns (uint256) {
        return _tracker[token].depositNonce;
    }

    event NonceUsed(address token, uint256 nonce, uint256 blockNumber);

    uint256[49] private __gap;
}