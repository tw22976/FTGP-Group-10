// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bank {
    using SafeMath for uint256;


    // Declare state variables
    uint256 public BASE_R = 1000;
    uint256 public MAX_R = 1800;
    uint256 public IN = 10000000;
    uint256 public OUT = 6000000;

    // Calculate INT using SafeMath functions
    function calculateInt() public view returns (uint256) {
        uint256 difference = MAX_R.sub(BASE_R);
        uint256 ratio = OUT.mul(1e18).div(IN); // Multiply by 1e18 to prevent loss of precision
        uint256 product = difference.mul(ratio).div(1e18); // Divide by 1e18 to restore the original precision
        uint256 INT = BASE_R.add(product);

        return INT;
    }




    // -- Borrower Array
    mapping(address => uint256[3]) private userArraysb;
    // Mapping to store the initialization status of a user's array
    mapping(address => bool) private initializedb;

    // -- Lender Array
    mapping(address => uint256[3]) private userArrays;

    // Mapping to store the initialization status of a user's data
    mapping(address => bool) private initialized;


 

    event LogMyVariable(uint256 value);
    

    // (1) Function to deposit collateral and initialize a new array for a unique address
    function borrowMoney(uint256 amount, uint256 r) public payable {
        
        if (!initializedb[msg.sender]) {
            initializedb[msg.sender] = true;
        } 
        require(userArraysb[msg.sender][0] == 0, "Already taken a loan.");
        userArraysb[msg.sender] = [amount, block.timestamp, r];

        OUT+= amount;
        IERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8).transferFrom(msg.sender, address(this), amount.mul(r).div(100));
        payable(msg.sender).transfer(amount);
        
        
    }

function bintPay() public payable {
    // Get the current interest rate from an external function
    uint interestRate = calculateInt();

    // Calculate the minimum deposit required to pay interest based on the current interest rate
    uint minDeposit = userArraysb[msg.sender][0].mul(interestRate).div(10000);
    emit LogMyVariable(minDeposit);
    // Require that the user's deposit is greater than the minimum deposit
    require(msg.value > minDeposit, "Deposit amount must be greater than minimum required to pay interest.");

    // Apply other constraints as necessary
    require(block.timestamp - userArraysb[msg.sender][1] > 60 && block.timestamp - userArraysb[msg.sender][1] < 120, "Timestamp must be greater than 60 and less than 120.");
    userArraysb[msg.sender][1] = block.timestamp;
    

    }

    // (3)Function to deposit principal
    function returnMoneyl() public payable {
        require(msg.value >= userArraysb[msg.sender][0], "Deposit amount must be greater than 0.");
        require(block.timestamp - userArraysb[msg.sender][1] < 600, "Failed to pay interest in time");

        // receiving back collateral
        IERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8).transferFrom(address(this), msg.sender, msg.value.mul(userArraysb[msg.sender][2]).div(100) );
        
        userArraysb[msg.sender] = [0,0,0];
        OUT-= msg.value;


        

    }
    // Function to retrieve the user's array
    function getArrayb() public view returns (uint256[3] memory) {
        require(initializedb[msg.sender], "User does not have an initialized array.");
        return userArraysb[msg.sender];
    }

    // Function to get the balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    // Lender side-----------------------------------------------------------------------------------------------------------------------------


    // (1)Function to deposit collateral and initialize a new data array for a unique address
    function ldeposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        // Get the current interest rate from an external function
        uint interestRate = calculateInt();

      


    if (!initialized[msg.sender]) {
        // Initialize user's data array if it hasn't been initialized
        initialized[msg.sender] = true;
        userArrays[msg.sender] = [msg.value, block.timestamp, 0];
        IN+=msg.value;
    } else {
        // Intrest calculation for the innitial deposit
        userArrays[msg.sender][2] += (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(200).mul(interestRate).div(10000);
        userArrays[msg.sender][0] += msg.value;
        userArrays[msg.sender][1] = block.timestamp;
        IN+=msg.value;
    }


    }

    // (2)Function to withdraw Ether as principal from the contract
    function lwithdraw(uint256 amount) public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][0] >= amount, "Insufficient balance for withdrawal.");

        uint interestRate = calculateInt();

        // Update user's interest and collateral
        userArrays[msg.sender][2] += (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(200).mul(interestRate).div(10000);
        userArrays[msg.sender][0] -= amount;
        userArrays[msg.sender][1] = block.timestamp;

        // Transfer Ether to the user
        payable(msg.sender).transfer(amount);
        IN-=amount;

 
    }

    // (3)Function to withdraw accumulated interest
    function lwithdrawInterest() public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");

        uint interestRate = calculateInt();
        // Calculate and transfer interest to the user
        uint256 interest = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(200).mul(interestRate).div(10000);
        payable(msg.sender).transfer(interest);

        // Update user's interest and deposit timestamp
        userArrays[msg.sender][2] = 0;
        userArrays[msg.sender][1] = block.timestamp;
    }
        uint interestRatel = calculateInt();
    uint256 interestl = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(200).mul(interestRatel).div(10000);

    // Function to withdraw both principal and interest
    function lwithdrawBoth() public {
        require(initialized[msg.sender], "User does not have an initialized array.");
        require(userArrays[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");
        uint interestRate = calculateInt();
        uint256 interest = userArrays[msg.sender][2] + (block.timestamp - userArrays[msg.sender][1]).mul(userArrays[msg.sender][0]).div(200).mul(interestRate).div(10000);
        uint256 totalAmount = userArrays[msg.sender][0] +  interest;
        // Calculate and transfer the total amount (principal + interest) to the user(userArrays[msg.sender][0]).div(1000);
    payable(msg.sender).transfer(totalAmount);    // Reset user's data array
        userArrays[msg.sender] = [0, 0, 0];
        IN-=userArrays[msg.sender][0];
    }

    // Function to get the user's data array
    function getArrayl() public view returns (uint256[3] memory) {
        require(initialized[msg.sender], "User does not have an initialized array.");
        return userArrays[msg.sender];
    }

}