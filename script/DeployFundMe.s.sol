// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {FundMe} from "../src/FundMe.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast means its not a real txn
        HelperConfig helperConfig = new HelperConfig();
        address ethPriceFeed = helperConfig.activeNetworkConfig();

        // After startBroadcast is a real txn
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
