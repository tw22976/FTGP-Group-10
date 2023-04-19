// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UserArray {
    using SafeMath for uint256;
    // Mapping to store users' arrays with 4 elements: collateral, deposit timestamp, interest payment timestamp, and array state
    mapping(address => uint256[4]) private userArrays;
    // Mapping to store the initialization status of a user's array
    mapping(address => bool) private initialized;

    // Event to log collateral deposits
    event Depositcol(address indexed user, uint256 amount);
    // Event to log interest payments
    event InterestPay(address indexed user, uint256 amount);
    // Event to log principal withdrawals
    event Withdrawal(address indexed user, uint256 amount);
    // Event to log principal deposits
    event PrincipalDeposit(address indexed user, uint256 amount);
    // Event to log collateral withdrawals
    event WithdrawCollateral(address indexed user, uint256 amount);

    // Function to deposit collateral and initialize a new array for a unique address
    function depositCol() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        if (!initialized[msg.sender]) {
            initialized[msg.sender] = true;
        } 
        require(userArrays[msg.sender][0] == 0, "Already taken a loan.");
        userArrays[msg.sender] = [msg.value, block.timestamp, block.timestamp, 1];
        // Emit an event to log the collateral deposit
        emit Depositcol(msg.sender, msg.value);
    }

    // Function to withdraw Ether as principal from the contract
    function withdrawPrincipal(uint256 amount) public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][0].div(10).mul(8) >= amount, "Insufficient balance for withdrawal.");
        require(userArrays[msg.sender][3] == 1, "Collateral not deposited.");

        userArrays[msg.sender][3] = 2;

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);

        // Emit an event to log the principal withdrawal
        emit Withdrawal(msg.sender, amount);
    }

    // Function to pay interest
    function intPay() public payable {
        require(msg.value > userArrays[msg.sender][0].div(10), "Deposit amount must be greater than 0.");
        require(block.timestamp - userArrays[msg.sender][2] > 60 && block.timestamp - userArrays[msg.sender][2] < 120, "Timestamp must be greater than 60 and less than 120.");
        userArrays[msg.sender][2] = block.timestamp;
        userArrays[msg.sender][3] = 3;

        // Emit an event to log the interest payment
        emit InterestPay(msg.sender, msg.value);
    }

    // Function to deposit principal
    function depositPrincipal() public payable {
        require(msg.value >= userArrays[msg.sender][0].mul(8).div(10), "Deposit amount must be greater than 0.");
        require(block.timestamp - userArrays[msg.sender][2] < 60, "Failed to pay interest in time");
        
        userArrays[msg.sender][3] = 4;

        // Emit an event to log the principal deposit
        emit PrincipalDeposit(msg.sender, msg.value);
    }

    // Function to withdraw collateral from the contract
    function withdrawCollateral(uint256 amount) public {
        require(userArrays[msg.sender][0] >= amount, "Insufficient balance for withdrawal.");
        require(userArrays[msg.sender][3] == 4, "Collateral not deposited.");
        
        userArrays[msg.sender] = [0, 0, 0, 0];

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);

        // Emit an event to log the collateral withdrawal
    emit WithdrawCollateral(msg.sender, amount);
    }
    // Function to retrieve the user's array
    function getArray() public view returns (uint256[4] memory) {
        require(initialized[msg.sender], "User does not have an initialized array.");
        return userArrays[msg.sender];
    }

    // Function to get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
