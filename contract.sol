// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UserArray {
    using SafeMath for uint256;
    // Mapping to store users' arrays with 4 elements: collateral, deposit timestamp, interest payment timestamp, and array state

    mapping (address => uint256) allowance ; 
    mapping (address => int) user_eth_balance ; 

    uint private col_balance ;
    uint private balance ; 
    int public profit ; 
    uint256 multiplier = 10**18;
    address private owner ; 

    function get_eth_balance() public view returns (uint) {
        return balance;
    }

    constructor(){

        owner = msg.sender;
    }

//--------------------------------------------------
// Owner 
    
    //Details

    function owner_detais() public view returns (address){
        return (owner);
    }

    // Withdraw

    function take_profit(uint amount) external payable {
        
        require(msg.sender == owner ,"Only owner can use this function");
        require(int(amount) <= profit ,"Profits are less, kindly check the amount ");
        payable (msg.sender).transfer(amount);
        profit -= int(amount);

    }
    
//--------------------------------------------------
// Handling Tokens 

    function deposit_tokens( uint256 amount) external {
        
        IERC20(0x2b34C3951561897178d6F5e3A0d0f9b64aEC91f5).transferFrom(msg.sender, address(this), amount);
        col_balance +=  amount * multiplier;
        allowance[msg.sender] += amount * multiplier;
    }

    function withdraw_token(uint amount) external {
        
        require(allowance[msg.sender] >= amount *multiplier ,"Approval Not Granted");
        IERC20(0x2b34C3951561897178d6F5e3A0d0f9b64aEC91f5).transferFrom(address(this), msg.sender, amount);
        col_balance -= amount * multiplier;
        allowance[msg.sender] -= amount*multiplier;
    }

//--------------------------------------------------
// Printing 

    function get_col_balance() public view returns(uint){
        return (col_balance / multiplier);
    }

    function get_user_allowance() public  view returns (uint){
        return allowance[msg.sender] /multiplier; 
    }

    function get_user_eth_balance() public  view returns (int){
        return user_eth_balance[msg.sender];
    }

//--------------------------------------------------
// Handling ETH

    // Deposit

    function deposit_eth() external payable {
        require(msg.value > 0, "Invalid deposit amount");
        balance += msg.value  ;
        user_eth_balance[msg.sender] += int(msg.value );
    }

    // Withdraw Borrower

    function withdraw_eth_borrower(uint amount) external payable {
        
        require(allowance[msg.sender] >= (amount) ,"Deposit Collateral to Withdraw");
        require(balance >= amount ,"Insufficient amount in the asset pool");
        payable (msg.sender).transfer(amount );
        user_eth_balance[msg.sender] -= int(amount);
        allowance[msg.sender] -= amount;
        balance -= amount ;
    }
    // Withdraw Lender 

        function withdraw_eth_lender(uint amount) external payable {
        require(user_eth_balance[msg.sender] >= int(amount) ,"You haven't deposited enough ETH");
        require(balance >= amount ,"Insufficient amount in the asset pool");
        payable (msg.sender).transfer(amount * 9/10);
        user_eth_balance[msg.sender] -= int(amount);
        balance -= amount ;
        profit = int(amount) * 1/10;

    }

// Interest handling

}
    // owner - 0xd7903fde54b66742896738c5e5071cd68924e5a7

   // acc1 - 0x36b4e5F8c8007E8EB96A488E4BdbA9103b574ED4

   // 0.01eth = 10000000000000000
