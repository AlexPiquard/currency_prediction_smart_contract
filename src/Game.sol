// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "chainlink-brownie-contracts\contracts\src\v0.4\interfaces\AggregatorV3Interface.sol";

/*
* @author AlexPiquard
* @notice Game smart contract for currency exchange rate evolution prediction.
*/
contract Game is Ownable {
    // @dev Percent of balance for owner of contract (in bps - one hundredth of 1 percentage point)
    uint256 public constant BPS_FOR_OWNER = 500; // 5%

    struct Bet {
        string currency;
        bool bet;
        uint256 amount;
    }

    struct Currency {
        AggregatorV3Interface dataFeed;
        uint80 lastRoundID;
        int lastPrice;
    }

    // @dev Iterable list of currency keys.
    string[] public currencyKeys = ["BTC", "ETH", "EUR"];
    // @dev Associated currencies for each key.
    mapping(string => Currency) private currencies;
    // @dev List of users of this round.
    address[] private users;
    // @dev Associated bet for each user in this round.
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
            int answer
        ) = currency.dataFeed.latestRoundData();
        return Currency(dataFeed, roundID, answer);
    }

    function betIncrease(uint256 amount, string calldata currency) public payable {
        bet(amount, 1, currency);
    }

    function betDecrease(uint256 amount, string calldata currency) public payable {
        bet(amount, 0, currency);
    }

    function bet(uint256 amount, bool state, string calldata currency) private {
        Bet bet = bets[msg.sender];
        if (bet == address(0x0)) {
            bet = Bet(currency, state, amount);
            bets[msg.sender] = bet;
        } else {
            require(bet.bet == state, "cant change bet");
            require(bet.currency == currency, "cant change currency");
            bet.amount += amount;
        }
    }

    // @notice Everyone can generate result, at his own cost.
    function result() public {
        // @dev Retrieve price state for each currency, and filter unchanged.
        mapping(string => bool) currencyStates;

        for (int i = 0; i < currencyKeys; ++i) {
            string currencyKey = currencyKeys[i];
            Currency oldCurrency = currencies[currencyKey];
            Currency currency = getLatestCurrencyData(oldCurrency.dataFeed);

            // @dev If roundID is still the same, do nothing.
            if (currency.lastRoundID == oldCurrency.lastRoundID) continue;

            // @dev Check if price increased or not.
            currencyStates[currencyKey] = currency.lastPrice > oldCurrency.lastPrice;
        }

        // @dev Get winners and sum bet amount.
        address[] winners = new address[];
        uint256 winnersBalance;

        for (int i = 0; i < users.length; ++i) {
            Bet bet = bets[users[i]];

            // @dev Check if he's wrong.
            if (bet.bet != currencyStates[bet.currency]) continue;

            winners.push(users[i]);
            winnersBalance += bet.amount;
        }

        // @dev Get balance and subtract contract percent.
        uint256 balance = address(this).balance;
        uint256 ownerGain = (balance * BPS_FOR_OWNER) / 10_000;
        balance -= ownerGain;
        winnersBalance -= ownerGain;

        // @dev Give money to winners.
        for (int i = 0; i < winners.length; ++i) {
            Bet bet = bets[winners[i]];

            // @dev Check if he's wrong.
            if (bet.bet != currencyStates[bet.currency]) continue;

            // @dev Give percent of balance to user, related to bet amount.
            payable(address(winners[i])).transfer((bet.amount*balance)/winnersBalance);
        }

        // @dev The rest goes to owner.
        payable(address(owner())).transfer(address(this).balance);
    }

    // @dev Reset game at end of round, after result.
    function reset() private {
        delete users;
        delete bets;
    }

}
