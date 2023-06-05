// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "chainlink-brownie-contracts\contracts\src\v0.4\interfaces\AggregatorV3Interface.sol";

contract Game is Ownable {
    uint256 public constant KEEP_PERCENT = 5;

    struct Bet {
        string currency;
        uint8 bet;
        uint256 amount;
    }

    struct Currency {
        AggregatorV3Interface dataFeed;
        uint80 lastRoundID;
        int lastPrice;
    }

    string[] public currencyKeys = ["BTC", "ETH", "EUR"];
    mapping(string => Currency) private currencies;
    // List of users of this round
    address[] private users;
    // List of bets for this round.
    mapping(address => Bet) private bets;

    constructor() {
        mapping(string => Currency) currenciesTmp;
        // Get default data for all supported currencies.
        currenciesTmp["BTC"] = getLatestCurrencyData(AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43));
        currenciesTmp["ETH"] = getLatestCurrencyData(AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306));
        currenciesTmp["EUR"] = getLatestCurrencyData(AggregatorV3Interface(0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910));
        currencies = currenciesTmp;
    }

    function getLatestCurrencyData(AggregatorV3Interface dataFeed) private view returns (Currency) {
        (
            uint80 roundID,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = currency.dataFeed.latestRoundData();
        return Currency(dataFeed, roundID, answer);
    }

    function betIncrease(uint256 amount, string calldata currency) public payable {
        Bet bet = bets[msg.sender];
        if (bet == address(0x0)) {
            bet = Bet(currency, 1, amount);
            bets[msg.sender] = bet;
        } else {
            require(bet.bet == 1, "cant change bet");
            require(bet.currency == currency, "cant change currency");
            bet.amount += amount;
        }
    }

    function betDecrease(uint256 amount, string calldata currency) public payable {
        Bet bet = bets[msg.sender];
        if (bet == address(0x0)) {
            bet = Bet(currency, 0, amount);
            bets[msg.sender] = bet;
        } else {
            require(bet.bet == 0, "cant change bet");
            bet.amount += amount;
        }
    }

    function roll() public {
        for (int i = 0; i < currencyKeys; ++i) {
            string currencyKey = currencyKeys[i];
            Currency oldCurrency = currencies[currencyKey];
            Currency currency = getLatestCurrencyData(oldCurrency.dataFeed);

            // If roundID is still the same, do nothing.
            if (currency.lastRoundID == oldCurrency.lastRoundID) continue;

            // Check if price increased or not.
            uint8 state = currency.lastPrice > oldCurrency.lastPrice;

//            for (int i = 0; i < users.length; ++i) {
//                Bet bet = bets[users[i]];
//                if (bet.currency == currencyKey) continue;
//            }

        }
    }

}
