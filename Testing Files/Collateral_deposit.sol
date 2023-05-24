// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract UserArray {
    // Mapping of address to an array of 3 elements
    mapping(address => uint256[3]) private userArrays;
    // Mapping to store the initialization status of an array
    mapping(address => bool) private initialized;

    // Event to log the deposit
    event Deposit(address indexed user, uint256 amount);
    // Event to log the withdrawal
    event Withdrawal(address indexed user, uint256 amount);

    // Join function to initialize a new array for a unique address
    function join() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        if (!initialized[msg.sender]) {
            userArrays[msg.sender] = [0, msg.value, 0];
            initialized[msg.sender] = true;
        } else {
            userArrays[msg.sender][1] += msg.value;
        }

        // Emit an event to log the deposit
        emit Deposit(msg.sender, msg.value);
    }



    // Function to retrieve the array
    function getArray() public view returns (uint256[3] memory) {
        require(initialized[msg.sender], "User does not have an initialized array.");
        return userArrays[msg.sender];
    }
    
    // Function to get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][1] >= amount, "Insufficient balance for withdrawal.");

        // Update user's balance
        userArrays[msg.sender][1] -= amount;

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);

        // Emit an event to log the withdrawal
        emit Withdrawal(msg.sender, amount);
    }
}
