
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bank {
using SafeMath for uint256;
// Variables for dynamic interest rate calculation
uint256 public BASE_INTEREST_RATE = 1000;
uint256 public MAX_INTEREST_RATE = 1800;
uint256 public TOTAL_DEPOSITED = 10e19;
uint256 public TOTAL_BORROWED = 7e19;
uint256 public TIME_CONVERSION = 6000; // Used to convert seconds to weeks

// Other variables

address public collateralTokenAddress = 0x39c573502c351629D9C28A91895b39A7960ebc38; // Collateral token address
uint256 public profit = 0; // Profits generated by the contract
uint256 public ex_rate = 100; //1 ETH = 1 CT (ex_rate =200, 1ETH = 2 CT)
address public owner;
uint256 public coll = 0;// Collateral in the contract

constructor() {
    owner = msg.sender;
}

// User reputation mapping
mapping(address => uint256) public reputation;

// Borrower mapping
mapping(address => uint256[3]) private borrowerData;
mapping(address => bool) private borrowerInitialized;

// Lender mapping
mapping(address => uint256[3]) private lenderData;
mapping(address => bool) private lenderInitialized;



// Borrower Functions
function borrowerDepositCollateral(uint256 amount, uint256 collateralPercentage) public payable {
    if (!borrowerInitialized[msg.sender]) {
        borrowerInitialized[msg.sender] = true;
    }
    require(collateralPercentage>=90,"Need more than 90% collatera");
    require(borrowerData[msg.sender][0] == 0, "Loan already taken.");
    require(reputation[msg.sender] >= amount.mul(110 - collateralPercentage).div(100), "Insufficient reputation.");

    borrowerData[msg.sender] = [amount, block.timestamp, collateralPercentage];

    IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), amount.mul(collateralPercentage).mul(ex_rate).div(10000));
    payable(msg.sender).transfer(amount);
    coll+=amount.mul(collateralPercentage).mul(ex_rate).div(10000);
    reputation[msg.sender] -= amount.mul(110 - collateralPercentage).div(100);
    TOTAL_BORROWED += amount;
}

function borrowerPayInterest() public payable {
    uint256 interestRate = calculateInterestRate()+ (110 - borrowerData[msg.sender][2]).mul(5) + 200;
    uint256 minDeposit = (block.timestamp-borrowerData[msg.sender][1])
                            .mul(borrowerData[msg.sender][0])
                            .div(TIME_CONVERSION)
                            .mul(interestRate)
                            .div(10000);
    require(msg.value >= minDeposit, "Deposit amount must be greater than minimum required to pay interest.");
    require(block.timestamp+TIME_CONVERSION-borrowerData[msg.sender][1]> 0, "Failed to pay on time.");

    borrowerData[msg.sender][1] =block.timestamp;
    profit += minDeposit.mul(2).div(100);
    reputation[msg.sender] += minDeposit.div(10);
}

function borrowerRepayLoan() public payable {
    (uint256 minDeposit, ) = calculateMinimumDeposit();
    require(msg.value >= borrowerData[msg.sender][0]+minDeposit, "Deposit amount must be greater than 0.");
    require(block.timestamp-borrowerData[msg.sender][1] > 0, "Failed to pay interest in time");
    

    IERC20(collateralTokenAddress).transferFrom(address(this), msg.sender, borrowerData[msg.sender][0].mul(borrowerData[msg.sender][2]).mul(ex_rate).div(10000));
    coll-=borrowerData[msg.sender][0].mul(borrowerData[msg.sender][2]).mul(ex_rate).div(10000);
    borrowerData[msg.sender] = [0, 0, 0];
    TOTAL_BORROWED -= msg.value;
    reputation[msg.sender] += msg.value.mul(110).div(100);
    
}

// Lender Functions
function lenderDeposit() public payable {
    require(msg.value > 0, "Deposit amount must be greater than 0.");
    uint256 interestRate = calculateInterestRate();

    if (!lenderInitialized[msg.sender]) {
        lenderInitialized[msg.sender] = true;
        lenderData[msg.sender] = [msg.value, block.timestamp, 0];
        TOTAL_DEPOSITED += msg.value;
    } else {
        lenderData[msg.sender][2] += (block.timestamp - lenderData[msg.sender][1])
                                        .mul(lenderData[msg.sender][0])
                                        .div(TIME_CONVERSION)
                                        .mul(interestRate)
                                        .div(10000);
        lenderData[msg.sender][0] += msg.value;
        lenderData[msg.sender][1] = block.timestamp;
        TOTAL_DEPOSITED += msg.value;
    }
}

function lenderWithdrawPrincipal(uint256 amount) public {
    require(lenderInitialized[msg.sender], "User does not have an initialized array.");
    require(lenderData[msg.sender][0] >= amount, "Insufficient balance for withdrawal.");

    uint256 interestRate = calculateInterestRate();

    lenderData[msg.sender][2] += (block.timestamp - lenderData[msg.sender][1])
                                    .mul(lenderData[msg.sender][0])
                                    .div(TIME_CONVERSION)
                                    .mul(interestRate)
                                    .div(10000);
    lenderData[msg.sender][0] -= amount;
    lenderData[msg.sender][1] = block.timestamp;

    payable(msg.sender).transfer(amount);
    TOTAL_DEPOSITED -= amount;
    reputation[msg.sender] += amount.div(10);
}

function lenderWithdrawInterest() public {
    require(lenderInitialized[msg.sender], "User does not have an initialized array.");
    require(lenderData[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");

    uint256 interestRate = calculateInterestRate();
    uint256 interest = lenderData[msg.sender][2] + (block.timestamp - lenderData[msg.sender][1])
                                    .mul(lenderData[msg.sender][0])
                                    .div(TIME_CONVERSION)
                                    .mul(interestRate)
                                    .div(10000);
    payable(msg.sender).transfer(interest);

    reputation[msg.sender] += interest;
    lenderData[msg.sender][2] = 0;
    lenderData[msg.sender][1] = block.timestamp;
}
function lendersInterest() public view returns (uint256) {
    require(lenderInitialized[msg.sender], "User does not have an initialized array.");
    require(lenderData[msg.sender][0] > 0, "Insufficient balance for withdrawal.");

    uint256 interestRate = calculateInterestRate();
    require(interestRate > 0, "Interest rate is 0.");

    uint256 timeSinceLastInteraction = block.timestamp - lenderData[msg.sender][1];
    uint256 fullPeriods = timeSinceLastInteraction.div(TIME_CONVERSION);
    uint256 partialPeriod = timeSinceLastInteraction % TIME_CONVERSION;

    uint256 interest = lenderData[msg.sender][0]
                        .mul(fullPeriods)
                        .mul(interestRate)
                        .div(10000);
    interest = interest.add(
        lenderData[msg.sender][0]
            .mul(partialPeriod)
            .mul(interestRate)
            .div(TIME_CONVERSION)
            .div(10000)
    );

    return interest;
}


function lenderWithdrawBoth() public {
    require(lenderInitialized[msg.sender], "User does not have an initialized array.");
    require(lenderData[msg.sender][0] >= 0, "Insufficient balance for withdrawal.");
        uint256 interestRate = calculateInterestRate();
    uint256 interest = lenderData[msg.sender][2] + (block.timestamp - lenderData[msg.sender][1])
                                    .mul(lenderData[msg.sender][0])
                                    .div(TIME_CONVERSION)
                                    .mul(interestRate)
                                    .div(10000);
    uint256 totalAmount = lenderData[msg.sender][0] + interest;

    payable(msg.sender).transfer(totalAmount);
    reputation[msg.sender] += totalAmount.div(10);

    lenderData[msg.sender] = [0, 0, 0];
    TOTAL_DEPOSITED -= lenderData[msg.sender][0];
}

// Admin Functions


modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function.");
    _;
}

function withdrawProfits(uint256 amount) public onlyOwner {
    require(profit > amount, "Insufficient profit to withdraw.");
    profit -= amount;
    address payable sender = payable(msg.sender);
    sender.transfer(amount);
}
function liquidate_collateral( uint256 amount) public onlyOwner {
        require(coll >= amount, "Insufficient token balance to withdraw.");
        IERC20(collateralTokenAddress).transfer(msg.sender, amount);
        coll-=amount;
    }
function calculateInterestRate() public view returns (uint256) {
    uint256 difference = MAX_INTEREST_RATE.sub(BASE_INTEREST_RATE);
    uint256 ratio = TOTAL_BORROWED.mul(1e18).div(TOTAL_DEPOSITED);
    uint256 product = difference.mul(ratio).div(1e18);
    uint256 interestRate = BASE_INTEREST_RATE.add(product);

    return interestRate;
}

function calculateMinimumDeposit() public view returns (uint256, uint256) {
    

    uint256 interestRate = calculateInterestRate()+ (110 - borrowerData[msg.sender][2]).mul(5) + 200;
    uint256 minDeposit = (block.timestamp-borrowerData[msg.sender][1])
                            .mul(borrowerData[msg.sender][0])
                            .div(TIME_CONVERSION)
                            .mul(interestRate)
                            .div(10000);
    
    return (minDeposit, TIME_CONVERSION+borrowerData[msg.sender][1]-block.timestamp  );// minimum deposit and time till next payment
}


// Utility Functions(for testing only)
function resetReputation(uint256 reputationAmount) public {
    reputation[msg.sender] = reputationAmount;
}
function exrate(uint256 rate) public {
    ex_rate = rate;
}

function resetLenderData() public {
    lenderData[msg.sender] = [0, 0, 0];
}

function resetBorrowerData() public {
    borrowerData[msg.sender] = [0, 0, 0];
}

function getUserData() public view returns (uint256[3] memory, uint256[3] memory, uint256) {
    return (borrowerData[msg.sender], lenderData[msg.sender], reputation[msg.sender]);
}

function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}
function extracoll(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0.");
        
        IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), amount);

    }
// Function to withdraw all Ether from this contract
function withdrawETH() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
}

}