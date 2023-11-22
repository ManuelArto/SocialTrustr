// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ContentSharing} from "../src/ContentSharing.sol";
import {ContentEvaluation} from "../src/ContentEvaluation.sol";
import {TrustToken} from "../src/TrustToken.sol";

contract DeployScript is Script {
    function run() external returns (
        ContentSharing contentSharing,
        ContentEvaluation contentEvaluation,
        TrustToken trustToken,
        HelperConfig helperConfig
    ) {
        helperConfig = new HelperConfig();
        (address ethUsdPriceeFeed, uint deadline) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        trustToken = new TrustToken(ethUsdPriceeFeed);
        contentSharing = new ContentSharing(trustToken);
        contentEvaluation = new ContentEvaluation(trustToken, deadline);
        // Add ContentSharing contract to ContentEvaluation
        contentEvaluation.setContentSharingContract(contentSharing);
        // Add admins to TrustToken and remove this contract
        trustToken.addAdmin(address(contentSharing));
        trustToken.addAdmin(address(contentEvaluation));
        trustToken.removeAdmin(address(this));
        vm.stopBroadcast();
    }
}
