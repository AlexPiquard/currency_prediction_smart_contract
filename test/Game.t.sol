// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract GameTest is Test {
    Game public game;
    MockV3Aggregator public dataFeed;
    address owner = makeAddr("owner");

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
        startHoax(owner, 2 ether);

        game.betIncrease{value: 1 ether}('MCK');
        game.addCurrencyFeed('PEP', new MockV3Aggregator(8, 800000000));

        vm.expectRevert("cant change currency");
        game.betIncrease{value: 1 ether}('PEP');
    }

    function testBetForFree() public {
        vm.expectRevert("cant bet for free");
        game.betDecrease{value: 0 ether}('MCK');
    }

    function testBetBalance(address user) public {
        startHoax(user, 1 ether);
        game.betDecrease{ value: 1 ether }('MCK');

        assertEq(user.balance, 0 ether);
        assertEq(address(game).balance, 1 ether);
    }

    function testBetAdd() public {
        startHoax(msg.sender, 2 ether);

        game.betDecrease{value: 1 ether}('MCK');
        game.betDecrease{value: 1 ether}('MCK');

        assertEq(game.getBetAmount(), 2 ether);
    }

    function testBet(address user, uint256 amount) public {
        vm.assume(amount > 0);

        startHoax(user, amount);

        game.betIncrease{value: amount}('MCK');
        assertEq(game.getBetAmount(), amount);
        assertEq(game.getBetCurrency(), 'MCK');
        assertEq(game.getBet(), true);
    }
}
