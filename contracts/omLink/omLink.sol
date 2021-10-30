// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

import "./core/SignVerifier.sol";
import "./includes/Fiber.sol";
import "./includes/Tracked.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @dev required interface for ERC20 compatible tokens
 * @notice the ERC20 is not fully implemented as omLink just requires 4 methods
 *
 */

interface ERC20Tokens {
    function burnFrom(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mintTo(address account, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract OmLink is Fiber, SignVerifier, Tracked
{

    using SafeERC20 for IERC20;

    /**
     * @dev chain ID of the contract where it is deployed
     *
     * 1 for ETH
     * 2 for BSC
     * 3 for omChain
     * 4 for Avalanche
     * 
     */
    uint256 public _chainId;

    /**
     * @dev finalizer struct because of the compiler error
     * this struct is used for finalizing the transaction on the target chain
     * 
     */
    struct finalizer {
        uint256 toChain;
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        uint256 nonce;
        address signer;
        bytes signature;
    }

    /** 
     * @dev set chainId
     * 
     */
    constructor(uint256 chainId) {
        _chainId = chainId;
    }


    /** 
     * @dev deposit function
     * 
     * emits {LinkStarted} event
     * 
     * @param toChain target chain id
     * @param token token contract address
     * @param to receiver address
     * @param amount amount of tokens to be transferred
     *
     * @return bool 
     */
    function deposit(
        uint256 toChain,
        address token,
        address to,
        uint amount
    ) public 
        onlySupportedToken(token) 
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        returns (bool) {

            /** 
             *
             * @dev Checks whether a token is LinkToken or not,
             * if the token is not LinkToken, it tansfers tokens from the user to the omLink contract
             * 
             */
            if(isLinkToken(token)) {
                require(ERC20Tokens(token).burnFrom(msg.sender,amount),"omLink: cannot burn tokens");
            } else {
                IERC20(token).safeTransferFrom(msg.sender,address(this),amount);
            }

            /**
             * 
             * @dev increment the deposit nonce of the said token so that 
             * backend servers won't reprocess the same events
             * this is required for event handling
             *
             */
            depositNonce(token);


            emit LinkStarted(toChain,token,msg.sender,to,amount,getDepositNonce(token));

            //in case contract is called by another contract later
            return true;
    }


    /**
     *
     * @dev implementation of the link finalizer, this function processes 
     * the coupon provided by the verified signer backend and mints & transfers 
     * the signed amount to the receiving address
     * 
     * Checks for whether the token is supported with `onlySupportedToken` modifier
     * Checks for blacklis with `notBlacklisted` modifier
     * Checks for whether contract is paused with `nonPaused` modifier
     * Checks whether the signature is from a verified signer with `onlyVerifiedSigner` modifier
     * 
     * @param toChain the chainId of the receiving chain
     * @param token the contract address of the token
     * @param from the sender
     * @param to the receiver
     * @param amount the amount of tokens to be minted & transferred from
     * @param nonce the nonce of the transaction coupon
     * @param signature the signed message from the server
     * @param signer the address of the coupon signer
     * 
     * @return bool 
     */
    function finalize(
        uint256 toChain,
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) public 
        onlySupportedToken(token) 
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        onlyVerifiedSigner(signer)
        returns (bool) {


            /** 
             * 
             * @dev makes sure that the coupon is being processed by the correct chain
             * and the nonce is not used before
             */
            require(_chainId == toChain,"omLink:incorrect chain");
            require(!isUsedNonce(token,nonce),"Tracked:used nonce");

            /** 
             * 
             * @dev passing function parameters to the `messageStruct_` element 
             * to solve the Stack too deep error and verifies whether the message is real or not
             *
             * 
             */
            
            Message memory messageStruct_;

            messageStruct_.networkId = toChain;
            messageStruct_.token = token;
            messageStruct_.from = from;
            messageStruct_.to = to;
            messageStruct_.amount = amount;
            messageStruct_.nonce = nonce;
            messageStruct_.signature = signature;
            messageStruct_.signer = signer;

            if( !verify(messageStruct_) ) {
                return false;
            }

            /** 
             * 
             * @dev uses the nonce on the current token address
             * and mints the token if it's mintable, transfers if not.
             */

            useNonce(token,nonce);
            if( isLinkToken(token) ) {
                ERC20Tokens(token).mintTo(to,amount);
            } else {
                ERC20Tokens(token).transfer(to,amount);
            }

            /** 
             * 
             * @dev emits {LinkFinalized} event to make sure the backend 
             * server also processes the coupon as used
             * 
             */
            emit LinkFinalized(
                messageStruct_.networkId,
                messageStruct_.token,
                messageStruct_.from,
                messageStruct_.to,
                messageStruct_.amount,
                messageStruct_.nonce,
                messageStruct_.signer);

            return true;
    }

    event LinkStarted(uint256 toChain, address tokenAddress, address from, address to, uint256 amount, uint256 indexed depositNonce);
    event LinkFinalized(uint256 chainId, address tokenAddress, address from, address to, uint256 amount, uint256 indexed nonce, address signer);



}