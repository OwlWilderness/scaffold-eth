pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//quantumtekh.eth
//road2web3 challenge 6 - staking dapp
//
// this implementation will allow users to stake a collection of 1155 tokens
// withdrawn token ids will be random ids with a range based on how long you stake

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract is Ownable {

//events
//
    event SetPurpose(address sender, string purpose);

//public variables
//
    string public purpose = "1155 Chaotic Staking App";

//mappings
//

//constructor
//
    constructor() payable {
      // what should we do on deploy?
    }

//controllers
//

//helpers
//
    function setPurpose(string memory newPurpose) public {
        purpose = newPurpose;
        console.log(msg.sender,"set purpose to",purpose);
        emit SetPurpose(msg.sender, purpose);
    }

//private functions
//

///common 
//
    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _addr, uint256 _amount) public onlyOwner{
        require(address(this).balance >= _amount, "amount exceeds funds");
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send ");
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}
}
