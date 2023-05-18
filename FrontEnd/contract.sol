
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositContract {
    address public owner;
    uint public balance;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "You must send some ether");
        balance += msg.value;
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        require(amount <= balance, "Insufficient balance");
        payable(owner).transfer(amount);
        balance -= amount;
    }

    function depositTo(address payable recipient) public payable {
        require(msg.sender == owner, "Only the owner can deposit funds to another address");
        require(recipient != address(0), "Invalid recipient address");
        require(msg.value > 0, "You must send some ether");

        recipient.transfer(msg.value);
        balance -= msg.value;
    }
}
