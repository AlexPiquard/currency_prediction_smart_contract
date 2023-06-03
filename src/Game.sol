// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Game is Ownable {
    uint256 public constant KEEP_PERCENT = 0.05;
    mapping(address => mapping(uint256 => mapping(string => uint8))) public bets;

    function betIncrease(uint256 amount, string currency) public payable {
        bets[msg.sender][currency][1] = amount;
    }

    function betDecrease(uint256 amount, string currency) public payable {
        bets[msg.sender][currency][0] = amount;
    }

}
