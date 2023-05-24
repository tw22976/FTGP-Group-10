// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// This smart contract allows users to deposit Ether as collateral, earn interest, and withdraw their principal and interest.
contract UserArray {
using SafeMath for uint256;

// Mapping to store users' data with 3 elements: collateral, deposit timestamp, and interest
mapping(address => uint256[3]) private userArrays;

// Mapping to store the initialization status of a user's data
mapping(address => bool) private initialized;

// Event to log collateral deposits
event Deposit(address indexed user, uint256 amount);
// Event to log interest withdrawals
event Interest(address indexed user, uint256 amount);
// Event to log principal withdrawals
event Withdrawal(address indexed user, uint256 amount);

// Function to deposit collateral and initialize a new data array for a unique address
function deposit() public payable {
    require(msg.value > 0, "Deposit amount must be greater than 0.");

    if (!initialized[msg.sender]) {
        // Initialize user's data array if it hasn't been initialized
        initialized[msg.sender] = true;
        userArrays[msg.sender] = [msg.value, block.timestamp, 0];
    } else {
        // Update user's interest and collateral
        userArrays[msg.sender][2] += (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(100);
        userArrays[msg.sender][0] += msg.value;
        userArrays[msg.sender][1] = block.timestamp;
    }

    // Emit an event to log the collateral deposit
    emit Deposit(msg.sender, msg.value);
}

// Function to withdraw Ether as principal from the contract
function withdraw(uint256 amount) public {
    require(initialized[msg.sender], "User does not have an initialized array.");
    require(userArrays[msg.sender][0] >= amount, "Insufficient balance for withdrawal.");

    // Update user's interest and collateral
    userArrays[msg.sender][2] += (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(1000);
    userArrays[msg.sender][0] -= amount;
    userArrays[msg.sender][1] = block.timestamp;

    // Transfer Ether to the user
    payable(msg.sender).transfer(amount);

    // Emit an event to log the principal withdrawal
    emit Withdrawal(msg.sender, amount);
}

// Function to withdraw accumulated interest
function withdrawInterest() public {
    require(initialized[msg.sender], "User does not have an initialized array.");
    require(userArrays[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");

    // Calculate and transfer interest to the user
    uint256 interest = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(1000);
    payable(msg.sender).transfer(interest);

    // Update user's interest and deposit timestamp
    userArrays[msg.sender][2] = 0;
    userArrays[msg.sender][1] = block.timestamp;
}

// Function to withdraw both principal and interest
function withdrawBoth() public {
    require(initialized[msg.sender], "User does not have an initialized array.");
    require(userArrays[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");
    uint256 interest = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(1000);
    uint256 totalAmount = userArrays[msg.sender][0] +  interest;
    // Calculate and transfer the total amount (principal + interest) to the user(userArrays[msg.sender][0]).div(1000);
payable(msg.sender).transfer(totalAmount);    // Reset user's data array
    userArrays[msg.sender] = [0, 0, 0];
}

// Function to get the user's data array
function getArray() public view returns (uint256[3] memory) {
    require(initialized[msg.sender], "User does not have an initialized array.");
    return userArrays[msg.sender];
}

// Function to get the balance of the contract
function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}
}
