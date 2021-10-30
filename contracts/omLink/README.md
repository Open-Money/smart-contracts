# omLink ERC-20 compliant token bridge

## Known issues

1. Because the finalize function takes 8 parameters, the input parameters had 
to be passed to a struct to handle the signature verification process. 

2. The contract is HUGE without optimization enabled on the compiler so it throws errors. 
Please enable optimizer + set runs to something like 200 to be able to compile the omLink contract 
successfully.

## Security 

This repo is maintained by <a href="https://openmoney.com.tr">Open Money</a>, and developed following latest standarts for code quality and security. Open Money contracts are meant to provide a general understanding of how smart contracts work. Most of the smart contracts here are tested and communmity-audited code, however there might be test versions of contracts and contracts written by team to experiment with the Solidity or Vyper language. Please use common sense and request code auditing from professionals when doing anything that deals with real money. We take no responsibility for your implementation decisions and any security problems you might experience. The source codes here are provided as is. 

Please report any security issues you find to info@openmoney.com.tr

Feel free to submit issues or pull requests for new features.

## License

The contracts and libraries provided on this repository are published under GNU AGPLv3 License. 