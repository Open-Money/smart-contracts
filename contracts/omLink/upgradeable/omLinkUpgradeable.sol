// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// osman@openmoney.com.tr

/**

    @notice The current upgradeable pattern haven't been 
    tested and is not completed. This contract is for educational 
    purposes only.

 */

import "./core/SignVerifierUpgradeable.sol";
import "./includes/FiberUpgradeable.sol";
import "./includes/TrackedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface ERC20Tokens {
    function burnFrom(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mintTo(address account, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract OmLinkUpgradeable is Initializable, FiberUpgradeable, SignVerifierUpgradeable, TrackedUpgradeable {

    /**
     * @dev chain ID of the contract where it is deployed
     *
     * 1 for ETH
     * 2 for BSC
     * 3 for omChain
     * 4 for Avalanche
     * 
     */
    
    uint256 public chainId;

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


    function __OmLink_init(uint256 chainId_) public initializer {
        __Fiber_init();
        __SignVerifier_init();
        __Tracked_init();
        __OmLink_init_unchained(chainId_);
    }

    function __OmLink_init_unchained(uint256 chainId_) public initializer {
        chainId = chainId_;
    }


    /** 
     * @dev deposit function
     * 
     * emits {LinkStarted} event
     * 
     * @param _toChain target chain id
     * @param _token token contract address
     * @param _to receiver address
     * @param _amount amount of tokens to be transferred
     * @param _message message to be delivered
     *
     * @return bool 
     */
    function deposit(
        uint256 _toChain,
        address _token,
        address _to,
        uint _amount,
        string memory _message
    ) public 
        onlySupportedToken(_token) 
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        nonPaused()
        returns (bool) {

            /** 
             *
             * @dev Checks whether a token is mintable or not, if mintable it means
             * The token is also burnable, so it burns the tokens from the msg.sender
             * if the token is not burnable, it tansfers tokens from the user to the omLink contract
             * 
             * @notice here the token must be an LToken form, because the burnFrom requires approval 
             * if it is implemented otherwise, however omLink's implementation allows 
             * burner role to burn from anyone, which will be provided to the omLink contract
             *
             */
            if(isMintableToken(_token)) {
                ERC20Tokens(_token).burnFrom(msg.sender,_amount);
            } else {
                ERC20Tokens(_token).transferFrom(msg.sender,address(this),_amount);
            }

            /**
             * 
             * @dev increment the deposit nonce of the said token so that 
             * backend servers won't reprocess the same events
             * this is required for event handling
             *
             */
            depositNonce(_token);


            emit LinkStarted(_toChain,msg.sender,_to,_amount,_message,_token,getDepositNonce(_token));

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
     * @param _toChain the chainId of the receiving chain
     * @param _token the contract address of the token
     * @param _from the sender
     * @param _to the receiver
     * @param _amount the amount of tokens to be minted & transferred from
     * @param _nonce the nonce of the transaction coupon
     * @param _signature the signed message from the server
     * @param _signer the address of the coupon signer
     * 
     * @return bool 
     */
    function finalize(
        uint256 _toChain,
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature,
        address _signer
    ) public 
        onlySupportedToken(_token) 
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        nonPaused()
        onlyVerifiedSigner(_signer)
        returns (bool) {


            /** 
             * 
             * @dev makes sure that the coupon is being processed by the correct chain
             * and the nonce is not used before
             */
            require(_toChain == chainId,"omLink:incorrect chain");
            require(!isUsedNonce(_token,_nonce),"Tracked:used nonce");

            /** 
             * 
             * @dev passing function parameters to the `messageStruct_` element 
             * to solve the Stack too deep error and verifies whether the message is real or not
             *
             * 
             */
            
            Message memory messageStruct_;

            messageStruct_.networkId = _toChain;
            messageStruct_.token = _token;
            messageStruct_.from = _from;
            messageStruct_.to = _to;
            messageStruct_.amount = _amount;
            messageStruct_.nonce = _nonce;
            messageStruct_.signature = _signature;
            messageStruct_.signer = _signer;

            if( !verify(messageStruct_) ) {
                return false;
            }

            /** 
             * 
             * @dev uses the nonce on the current token address
             * and mints the token if it's mintable, transfers if not.
             */

            useNonce(_token,_nonce);
            if( isMintableToken(_token) ) {
                ERC20Tokens(_token).mintTo(_to,_amount);
            } else {
                ERC20Tokens(_token).transfer(_to,_amount);
            }

            /** 
             * 
             * @dev emits {LinkFinalized} event to make sure the backend 
             * server also processes the coupon as used
             * 
             */
            emit LinkFinalized(
                messageStruct_.from,
                messageStruct_.to,
                messageStruct_.amount,
                messageStruct_.token,
                messageStruct_.nonce,
                messageStruct_.networkId,
                messageStruct_.signer);

            return true;
    }


    event LinkStarted(uint256 toChain, address from, address to, uint256 amount, string memo, address tokenAddress, uint256 indexed depositNonce);
    event LinkFinalized(address from, address to, uint256 amount, address tokenAddress, uint256 indexed nonce, uint256 chainId, address signer);

}