// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {TrustToken} from "../src/TrustToken.sol";

contract DeployScript is Script {
    function run() external returns (
        NewsSharing newsSharing,
        NewsEvaluation newsEvaluation,
        TrustToken trustToken,
        HelperConfig helperConfig
    ) {
        helperConfig = new HelperConfig();
        (address ethUsdPriceeFeed, uint deadline) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        trustToken = new TrustToken(ethUsdPriceeFeed);
        newsSharing = new NewsSharing(trustToken);
        newsEvaluation = new NewsEvaluation(trustToken, deadline);
        // Add NewsSharing contract to NewsEvaluation
        newsEvaluation.setNewsSharingContract(newsSharing);
        // Add admins to TrustToken and remove this contract
        trustToken.addAdmin(address(newsSharing));
        trustToken.addAdmin(address(newsEvaluation));
        trustToken.removeAdmin(address(this));
        vm.stopBroadcast();
    }
}
