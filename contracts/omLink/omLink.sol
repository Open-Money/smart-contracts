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
     * 1 for ETH mainnet
     * 3 for ETH ropsten testnet
     * 4 for ETH rinkeby testnet
     * 5 for ETH goerli testnet
     * 
     * 56 for BSC mainnet
     * 97 for BSC testnet
     *
     * 43114 for Avalanche mainnet
     * 43113 for Avalanche testnet
     *
     * 9102020 for omChain Jupiter testnet
     * 21816 for omChain mainnet
     * 14521 for omChain local testnet 1
     * 14522 for omChain local testnet 2
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
        uint256 amount
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
     * @dev deposit function for native tokens
     * 
     * emits {LinkStarted} event with address(0) as contract address
     * 
     * @param toChain target chain id
     * @param to receiving address
     * @param amount receiving amount
     *
     * @return bool
     *
     */
    function depositNative(
        uint256 toChain,
        address to,
        uint256 amount
    ) payable public 
        isSupportedNative()
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        returns (bool) {
            /**
             * @dev checks whether the amount calling the function 
             * is equal with the actual transacted native token
             * reverts if not
             *
             * @notice because the native token deposit is already 
             * credited with the transaction, we don't require 
             * any transfer event
             */
            require(msg.value == amount,"omLink: wrong native amount");

            /**
             * @dev increments the native deposit nonce
             *
             */
            nativeDepositNonce();

            emit LinkStarted(toChain,address(0),msg.sender,to,amount,getNativeDepositNonce());

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

            require(verify(messageStruct_),"omLink: signature cant be verified");

            /** 
             * 
             * @dev uses the nonce on the current token address
             * and mints the token if it's mintable, transfers if not.
             */

            useNonce(token,nonce);

            if( isLinkToken(token) ) {
                ERC20Tokens(token).mintTo(to,amount);
            } else {
                IERC20(token).safeTransfer(to,amount);
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

    /**
     * 
     * @dev implementation of the link finalizer on receiving native currency
     * this function processes the coupon provided by the verified signer and 
     * transfers the amount of native tokens to the receiving address
     *
     * Checks for whether native token bridging is supported on deployed network
     * Checks whether the sending or receiving address is blacklisted
     * Checks for signature provided and signer
     *
     * @param toChain the chainId of the receiving chain
     * @param from the sender
     * @param to the receiver
     * @param amount the amount of tokens to be minted & transferred from
     * @param nonce the nonce of the transaction coupon
     * @param signature the signed message from the server
     * @param signer the address of the coupon signer
     * 
     * @return bool
     * */
    function finalizeNative(
        uint256 toChain,
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) public 
        isSupportedNative()
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        onlyVerifiedSigner(signer)
        returns (bool) {
            require(_chainId == toChain,"omLink:incorrect chain");
            require(!isUsedNativeNonce(nonce),"Tracked:used nonce");

            NativeMessage memory messageStruct_;

            messageStruct_.networkId = toChain;
            messageStruct_.from = from;
            messageStruct_.to = to;
            messageStruct_.amount = amount;
            messageStruct_.nonce = nonce;
            messageStruct_.signature = signature;
            messageStruct_.signer = signer;

            require(verifyNative(messageStruct_),"omLink: message cant be verified");
            require(address(this).balance >= amount,"omLink: not enough native");

            useNativeNonce(nonce);

            address payable receiver = payable(to);
            receiver.transfer(amount);

            emit LinkFinalized(
                messageStruct_.networkId,
                address(0),
                messageStruct_.from,
                messageStruct_.to,
                messageStruct_.amount,
                messageStruct_.nonce,
                messageStruct_.signer
            );

            return true;

        }

    function invalidateNonce(address token, uint256 nonce) public onlyOwner returns (bool) {
        
        require(!isUsedNonce(token,nonce),"Tracked:used nonce");
        useNonce(token,nonce);

        emit NonceInvalidated(_chainId,token,msg.sender,nonce,block.number);
        return true;
    }

    function invalidateNative(uint256 nonce) public onlyOwner returns (bool) {
        require(!isUsedNativeNonce(nonce),"Tracked:used nonce");
        useNativeNonce(nonce);

        emit NativeNonceInvalidated(_chainId,msg.sender,nonce,block.number);
        return true;
    }


    event LinkStarted(uint256 toChain, address tokenAddress, address from, address to, uint256 amount, uint256 indexed depositNonce);
    event LinkFinalized(uint256 chainId, address tokenAddress, address from, address to, uint256 amount, uint256 indexed nonce, address signer);
    
    event NonceInvalidated(uint256 chainId, address tokenAddress, address owner, uint256 indexed nonce, uint atBlock);
    event NativeNonceInvalidated(uint256 chainId, address owner, uint256 indexed nonce, uint atBlock);

}