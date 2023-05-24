
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    event Received(address indexed from, uint256 value);

    function myPayableFunction() payable public {
        emit Received(msg.sender, msg.value);
        
        // Your code to handle the incoming ETH transaction here
        // For example, you could transfer the ETH to another account like this:
        address payable recipient = payable(0xB2e8a15dFD0EFBd022825DA12Fd061b858f19CD3); // Replace with recipient address
        recipient.transfer(msg.value);
    }
}

