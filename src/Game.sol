// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Game is Ownable {
    AggregatorV3Interface internal dataFeed;
    uint256 public constant KEEP_PERCENT = 5;
    mapping(address => mapping(string => mapping(uint8 => uint256))) public bets;

    constructor() {
        dataFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );
    }

    function getLatestData() public view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function betIncrease(uint256 amount, string calldata currency) public payable {
        bets[msg.sender][currency][uint8(1)] = amount;
    }

    function betDecrease(uint256 amount, string calldata currency) public payable {
        bets[msg.sender][currency][uint8(0)] = amount;
    }

}
