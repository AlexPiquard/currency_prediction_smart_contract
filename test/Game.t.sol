// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract GameTest is Test {
    Game public game;
    MockV3Aggregator public dataFeed;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        vm.startPrank(owner);

        dataFeed = new MockV3Aggregator(8, 174183000000);
        game = new Game();
        game.addCurrencyFeed('MCK', dataFeed);

        vm.stopPrank();
    }

    function testInitialData() public {
        assertEq(game.getBetAmount(), 0);
        assertEq(game.getBetCurrency(), "");
        assertEq(game.getBet(), false);
    }

    function testUnauthorized(address user) public {
        vm.assume(user != owner);
        vm.startPrank(user);

        MockV3Aggregator mock = new MockV3Aggregator(8, 800000000);

        vm.expectRevert("Ownable: caller is not the owner");
        game.addCurrencyFeed('KEK', mock);

        vm.stopPrank();
    }

    function testAddFeed() public {
        vm.startPrank(owner);

        game.addCurrencyFeed('PEP', new MockV3Aggregator(8, 800000000));
        assertEq(game.getSupportedCurrencies()[1], 'PEP');

        vm.stopPrank();
    }

    function testClearCurrencies() public {
        vm.startPrank(owner);

        game.clearCurrencies();
        assertEq(game.getSupportedCurrencies().length, 0);

        vm.stopPrank();
    }

    function testBetUnknownCurrency() public {
        vm.expectRevert("unsupported currency");
        game.betIncrease{value: 1 ether}('KEK');
    }

    function testBetCantChangeBet() public {
        game.betIncrease{value: 1 ether}('MCK');

        vm.expectRevert("cant change bet");
        game.betDecrease{value: 1 ether}('MCK');
    }

    function testBetCantChangeCurrency() public {
        MockV3Aggregator mock = new MockV3Aggregator(8, 800000000);

        hoax(owner, 1 ether);
        game.betIncrease{value: 1 ether}('MCK');
        vm.prank(owner);
        game.addCurrencyFeed('PEP', mock);

        vm.expectRevert("cant change currency");
        hoax(owner, 1 ether);
        game.betIncrease{value: 1 ether}('PEP');
    }

    function testBetForFree() public {
        vm.expectRevert("cant bet for free");
        game.betDecrease{value: 0 ether}('MCK');
    }

    function testBetBalance() public {
        hoax(user1, 1 ether);
        game.betDecrease{ value: 1 ether }('MCK');

        assertEq(user1.balance, 0);
        assertEq(address(game).balance, 1 ether);
    }

    function testBetAdd() public {
        hoax(owner, 1 ether);
        game.betDecrease{value: 1 ether}('MCK');
        hoax(owner, 1 ether);
        game.betDecrease{value: 1 ether}('MCK');

        hoax(owner);
        assertEq(game.getBetAmount(), 2 ether);
    }

    function testBet(uint256 amount) public {
        vm.assume(amount > 0);

        hoax(user1, amount);
        game.betIncrease{value: amount}('MCK');

        hoax(user1);
        assertEq(game.getBetAmount(), amount);
        hoax(user1);
        assertEq(game.getBetCurrency(), 'MCK');
        hoax(user1);
        assertEq(game.getBet(), true);
    }

    function testResultSameRound() public {
        hoax(user1, 1 ether);
        game.betIncrease{value: 1 ether}('MCK');

        game.result();
        assertEq(user1.balance, 0);
    }

    function testResult(int newPrice) public {
        hoax(user1, 70);
        game.betIncrease{value: 70}('MCK');
        hoax(user2, 30);
        game.betDecrease{value: 30}('MCK');

        dataFeed.updateAnswer(newPrice);
        game.result();

        if (newPrice > 174183000000) {
            assertEq(user1.balance, 95);
            assertEq(user2.balance, 0);
        } else {
            assertEq(user1.balance, 0);
            assertEq(user2.balance, 95);
        }
        assertEq(owner.balance, 5);
    }

    function testResultSplitBalance(uint256 amount, uint256 amount2) public {
        vm.assume(amount > 0);
        vm.assume(amount2 > 0);
        vm.assume(amount < 100 ether);
        vm.assume(amount2 < 100 ether);

        MockV3Aggregator mock = new MockV3Aggregator(8, 100000000);
        vm.prank(owner);
        game.addCurrencyFeed('PEP', mock);

        hoax(user1, amount);
        game.betIncrease{value: amount}('MCK');
        hoax(user2, amount2);
        game.betIncrease{value: amount2}('PEP');

        dataFeed.updateAnswer(800000000000);
        mock.updateAnswer(800000000000);
        game.result();

        uint256 ownerGain = (amount + amount2) * game.PERCENT_FOR_OWNER() / 100;
        uint256 balance = amount + amount2;

        if (balance > ownerGain)
            balance -= ownerGain;

        assertEq(user1.balance, amount * balance / (amount + amount2));
        assertEq(user2.balance, amount2 * balance / (amount + amount2));
        assertEq(owner.balance, amount + amount2 - user1.balance - user2.balance);
    }

    function testResultCheater() public {
        dataFeed.updateAnswer(800000000000);

        vm.warp(block.timestamp + 1000);

        hoax(user1, 1 ether);
        game.betIncrease{value: 1 ether}('MCK');
        game.result();

        assertEq(user1.balance, 0);
    }
}
