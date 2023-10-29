// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract ShareNews is Script {

    function shareNews(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        NewsSharing(payable(mostRecentlyDeployed));
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NewsSharing", block.chainid);
        shareNews(mostRecentlyDeployed);
    }
}