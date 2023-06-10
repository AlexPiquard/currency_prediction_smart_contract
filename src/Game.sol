// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
* @author AlexPiquard
* @notice Game smart contract for currency exchange rate evolution prediction.
*/
contract Game is Ownable {
    // @dev Percent of balance for owner of the contract (in bps - one hundredth of 1 percentage point)
    uint256 public constant BPS_FOR_OWNER = 500; // 5%

    struct Bet {
        string currency;
        bool bet;
        uint256 amount;
    }

    struct Currency {
        AggregatorV3Interface dataFeed;
        uint80 lastRoundID;
        uint80 currentRoundID;
        int lastPrice;
        int currentPrice;
    }

    // @dev Iterable list of currency keys.
    string[] private currencyKeys;
    // @dev Associated currencies for each key.
    mapping(string => Currency) private currencies;
    // @dev List of users of this round.
    address[] private users;
    // @dev Associated bet for each user in this round.
    mapping(address => Bet) private bets;

    constructor() Ownable() {}

    function addCurrencyFeed(string memory currencyKey, AggregatorV3Interface dataFeed) public onlyOwner {
        (
            uint80 roundID,
            int answer,
            /*uint256 startedAt*/,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = (dataFeed).latestRoundData();

        // @dev If the round is not complete yet, updatedAt is 0
        require(updatedAt > 0, "Round not complete");

        currencies[currencyKey] = Currency(dataFeed, 0, roundID, 0, answer);
        currencyKeys.push(currencyKey);
    }

    function clearCurrencies() public onlyOwner {
        for (uint256 i = 0; i < currencyKeys.length; ++i) {
            delete currencies[currencyKeys[i]];
        }
        delete currencyKeys;
    }

    function updateLatestCurrencyData(string memory currencyKey) private {
        Currency memory currency = currencies[currencyKey];
        (
            uint80 roundID,
            int answer,
            /*uint256 startedAt*/,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = (currency.dataFeed).latestRoundData();

        // @dev If the round is not complete yet, updatedAt is 0
        require(updatedAt > 0, "Round not complete");

        currency.lastRoundID = currency.currentRoundID;
        currency.lastPrice = currency.currentPrice;
        currency.currentRoundID = roundID;
        currency.currentPrice = answer;

        currencies[currencyKey] = currency;
    }

    function betIncrease(string memory currency) public payable {
        bet(msg.value, true, currency);
    }

    function betDecrease(string memory currency) public payable {
        bet(msg.value, false, currency);
    }

    function getBetAmount() public view returns (uint256) {
        return bets[msg.sender].amount;
    }

    function getBetCurrency() public view returns (string memory) {
        return bets[msg.sender].currency;
    }

    function getBet() public view returns (bool) {
        return bets[msg.sender].bet;
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return currencyKeys;
    }

    function bet(uint256 amount, bool state, string memory currency) private {
        require(amount > 0, "cant bet for free");
        require(address(currencies[currency].dataFeed) != address(0), "unsupported currency");

        Bet memory b = bets[msg.sender];
        if (b.amount == 0) {
            b = Bet(currency, state, amount);
            bets[msg.sender] = b;
        } else {
            require(b.bet == state, "cant change bet");
            require(keccak256(bytes(b.currency)) == keccak256(bytes(currency)), "cant change currency");
            b.amount += amount;
            bets[msg.sender] = b;
        }
    }

    // @notice Everyone can generate result, at his own cost.
    function result() public {
        // @dev Update data for all currencies.
        for (uint256 i = 0; i < currencyKeys.length; ++i) {
            updateLatestCurrencyData(currencyKeys[i]);
        }

        // @dev Get winners and sum bet amount.
        address[] memory winners = new address[](users.length);
        uint256 winnersBalance;

        for (uint256 i = 0; i < users.length; ++i) {
            Bet memory b = bets[users[i]];
            Currency memory currency = currencies[b.currency];

            // @dev If round is still the same for this currency, we do nothing.
            if (currency.lastRoundID == currency.currentRoundID) continue;

            // @dev Check if he's wrong.
            if (b.bet != (currency.currentPrice > currency.lastPrice)) continue;

            winners[i] = users[i];
            winnersBalance += b.amount;
        }

        // @dev Get balance and subtract contract percent.
        uint256 balance = address(this).balance;
        uint256 ownerGain = (balance * BPS_FOR_OWNER) / 10_000;
        balance -= ownerGain;
        winnersBalance -= ownerGain;

        // @dev Give money to winners.
        for (uint256 i = 0; i < winners.length; ++i) {
            if (winners[i] == address(0)) continue;

            Bet memory b = bets[winners[i]];

            // @dev Give percent of balance to user, related to bet amount.
            payable(address(winners[i])).transfer((b.amount*balance)/winnersBalance);
        }

        // @dev The rest goes to owner.
        payable(address(owner())).transfer(address(this).balance);

        reset();
    }

    // @dev Reset game at end of round, after result.
    function reset() private {
        for (uint256 i = 0; i < users.length; ++i) {
            delete bets[users[i]];
        }
        delete users;
    }
}
