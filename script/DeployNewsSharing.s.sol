// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";

contract DeployNewsSharing is Script {

    function run() external returns (NewsSharing newsSharing) {
        vm.startBroadcast();
        newsSharing = new NewsSharing();
        vm.stopBroadcast();
    }

}