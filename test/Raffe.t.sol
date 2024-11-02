// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Raffe} from "../src/Raffe.sol";

contract RaffeTest is Test {
    Raffe public raffe;

    function setUp() public {
        raffe = new Raffe();
    }
}
