// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";

contract DeployScript is Script {
    
    function run()
        external
        returns (NewsSharing newsSharing, NewsEvaluation newsEvaluation)
    {
        vm.startBroadcast();
        newsSharing = new NewsSharing();
        newsEvaluation = new NewsEvaluation();
        vm.stopBroadcast();
    }
}
