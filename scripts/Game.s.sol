// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Game.sol";

contract GameScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Game game = new Game();
        vm.stopBroadcast();
    }
}