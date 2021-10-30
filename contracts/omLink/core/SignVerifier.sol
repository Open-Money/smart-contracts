// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

contract SignVerifier {

    struct Message {
        uint256 networkId;
        address token;
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        bytes signature;
        address signer;
    }

    /**
     * @dev function that returns the hash of the encoded message
     * @param networkId ID of the network
     * @param token the address of the token's contract
     * @param from the address of the sender
     * @param to the address of the receiver
     * @param amount the amount of tokens
     * @param nonce the nonce of the message
     *
     * @return bytes32 message hash
     */
    function getMessageHash(
        uint256 networkId, 
        address token, 
        address from, 
        address to, 
        uint256 amount, 
        uint256 nonce
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(networkId,token,from,to,amount,nonce));
    }

    /**
     * @dev converts the signed message to the ETH signed message format
     * by appending \x19Ethereum Signed Message:\n32
     * 
     * @param messageHash the hash of the message
     * @return bytes32
     */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
    
    /**
     * @dev the function that verifys that a message is indeed signed by the passed signer
     * 
     * @param finalizeMessage a struct that has the message data
     * 
     * @return bool, true if signer is correct, false if not
     *
     */
    function verify(
        Message memory finalizeMessage
    )
        public pure returns (bool)
    {
        bytes32 messageHash_ = getMessageHash(
            finalizeMessage.networkId,
            finalizeMessage.token,
            finalizeMessage.from,
            finalizeMessage.to,
            finalizeMessage.amount,
            finalizeMessage.nonce);
        bytes32 ethSignedMessageHash_ = getEthSignedMessageHash(messageHash_);

        return recoverSigner(ethSignedMessageHash_, finalizeMessage.signature) == finalizeMessage.signer;
    }

    /**
     * @dev function that recovers the signer of an eth signed message hash from signature
     * 
     * @param ethSignedMessageHash signed message hash
     * @param signature signature
     *
     * @return address of the signer
     */
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }



    /**
     * @dev function that splits the signature
     * 
     * @param sig signature
     * 
     * @return r bytes32
     * @return s bytes32
     * @return v uint8
     */

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "SignVerifier: invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

    }

}