// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {TrustToken} from "../src/TrustToken.sol";

contract DeployScript is Script {
    function run()
        external
        returns (
            NewsSharing newsSharing,
            NewsEvaluation newsEvaluation,
            TrustToken trustToken
        )
    {
        vm.startBroadcast();
        trustToken = new TrustToken();
        newsSharing = new NewsSharing(trustToken);
        newsEvaluation = new NewsEvaluation(trustToken);
        // Add contract to each oher
        newsEvaluation.setNewsSharingContract(newsSharing);
        newsSharing.setNewsEvaluationContract(newsEvaluation);
        // Add admins to TrustToken
        trustToken.addAdmin(address(newsSharing));
        trustToken.addAdmin(address(newsEvaluation));
        vm.stopBroadcast();
    }
}
