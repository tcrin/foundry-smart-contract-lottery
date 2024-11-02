// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffe} from "../src/Raffe.sol";

contract RaffeScript is Script {
    Raffe public raffe;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        raffe = new Raffe();

        vm.stopBroadcast();
    }
}
