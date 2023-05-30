// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Game is ERC20 {
    uint256 public constant KEEP_PERCENT = 0.05;

    address public owner;
    mapping(address => uint256) public bets;

    constructor() ERC20("Token", "TKN") {
        owner = msg.sender;
    }

    function betIncrease(uint256 amount, string currency) public {

    }

    function betDecrease(uint256 amount, string currency) public {

    }
}
