// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bank {
    using SafeMath for uint256;
    // Mapping to store users' arrays with 4 elements: collateral, deposit timestamp, interest payment timestamp, and array state
    mapping(address => uint256[4]) private userArraysb;
    // Mapping to store the initialization status of a user's array
    mapping(address => bool) private initializedb;

    mapping(address => uint256[3]) private userArrays;

    // Mapping to store the initialization status of a user's data
    mapping(address => bool) private initialized;

    // Event to log collateral deposits
    event Depositcol(address indexed user, uint256 amount);
    // Event to log interest payments
    event InterestPay(address indexed user, uint256 amount);
    // Event to log principal withdrawals
    event Withdrawalb(address indexed user, uint256 amount);
    // Event to log principal deposits
    event PrincipalDeposit(address indexed user, uint256 amount);
    // Event to log collateral withdrawals
    event WithdrawCollateral(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    // Event to log interest withdrawals
    event Interest(address indexed user, uint256 amount);
    // Event to log principal withdrawals
    event Withdrawal(address indexed user, uint256 amount);

    // Function to deposit collateral and initialize a new array for a unique address
    function bdepositCol() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        if (!initializedb[msg.sender]) {
            initializedb[msg.sender] = true;
        } 
        require(userArraysb[msg.sender][0] == 0, "Already taken a loan.");
        userArraysb[msg.sender] = [msg.value, block.timestamp, block.timestamp, 1];
        // Emit an event to log the collateral deposit
        emit Depositcol(msg.sender, msg.value);
    }

    // Function to withdraw Ether as principal from the contract
    function bwithdrawPrincipal(uint256 amount) public {
        require(initializedb[msg.sender], "User does not have an initialized array.");
        require(userArraysb[msg.sender][0].div(10).mul(8) >= amount, "Insufficient balance for withdrawal.");
        require(userArraysb[msg.sender][3] == 1, "Collateral not deposited.");

        userArraysb[msg.sender][3] = 2;

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);

        // Emit an event to log the principal withdrawal
        emit Withdrawalb(msg.sender, amount);
    }

    // Function to pay interest
    function bintPay() public payable {
        require(msg.value > userArraysb[msg.sender][0].div(10), "Deposit amount must be greater than 0.");
        require(block.timestamp - userArraysb[msg.sender][2] > 60 && block.timestamp - userArraysb[msg.sender][2] < 120, "Timestamp must be greater than 60 and less than 120.");
        userArraysb[msg.sender][2] = block.timestamp;
        userArraysb[msg.sender][3] = 3;

        // Emit an event to log the interest payment
        emit InterestPay(msg.sender, msg.value);
    }

    // Function to deposit principal
    function bdepositPrincipal() public payable {
        require(msg.value >= userArraysb[msg.sender][0].mul(8).div(10), "Deposit amount must be greater than 0.");
        require(block.timestamp - userArraysb[msg.sender][2] < 60, "Failed to pay interest in time");
        
        userArraysb[msg.sender][3] = 4;

        // Emit an event to log the principal deposit
        emit PrincipalDeposit(msg.sender, msg.value);
    }

    // Function to withdraw collateral from the contract
    function bwithdrawCollateral(uint256 amount) public {
        require(userArraysb[msg.sender][0] >= amount, "Insufficient balance for withdrawal.");
        require(userArraysb[msg.sender][3] == 4, "Collateral not deposited.");
        
        userArraysb[msg.sender] = [0, 0, 0, 0];

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);

        // Emit an event to log the collateral withdrawal
    emit WithdrawCollateral(msg.sender, amount);
    }
    // Function to retrieve the user's array
    function getArrayb() public view returns (uint256[4] memory) {
        require(initializedb[msg.sender], "User does not have an initialized array.");
        return userArraysb[msg.sender];
    }

    // Function to get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // Lender side


    // Function to deposit collateral and initialize a new data array for a unique address
    function ldeposit() public payable {
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
    function lwithdraw(uint256 amount) public {
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
    function lwithdrawInterest() public {
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
    function lwithdrawBoth() public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");
        uint256 interest = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(1000);
        uint256 totalAmount = userArrays[msg.sender][0] +  interest;
        // Calculate and transfer the total amount (principal + interest) to the user(userArrays[msg.sender][0]).div(1000);
    payable(msg.sender).transfer(totalAmount);    // Reset user's data array
        userArrays[msg.sender] = [0, 0, 0];
    }

    // Function to get the user's data array
    function getArrayl() public view returns (uint256[3] memory) {
        require(initialized[msg.sender], "User does not have an initialized array.");
        return userArrays[msg.sender];
    }

}