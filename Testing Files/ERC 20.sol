// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyToken {
    string public constant name = "Collateral Token";
    string public constant symbol = "CT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    
    mapping(address => uint256) balances;


    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        totalSupply = 1000 * 10 ** decimals ;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transferFrom(address owner, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[owner], "Insufficient balance");

        balances[owner] -= amount;
        balances[recipient] += amount;

        emit Transfer(owner, recipient, amount);
        return true;
    }
}

 // ac 1 - 0x36b4e5F8c8007E8EB96A488E4BdbA9103b574ED4

// owner -  0xD7903FdE54b66742896738c5E5071cd68924e5A7