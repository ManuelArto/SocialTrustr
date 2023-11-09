// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract EvaluateNews is Script {
    function evaluateNews(
        address mostRecentlyDeployed,
        uint newsId,
        bool evaluation,
        uint confidence
    ) public {
        vm.startBroadcast();
        NewsEvaluation newsEvaluation = NewsEvaluation(
            payable(mostRecentlyDeployed)
        );
        newsEvaluation.evaluateNews(newsId, evaluation, confidence);
        vm.stopBroadcast();
    }

    function run(uint newsId, bool evaluation, uint confidence) external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsEvaluation",
            block.chainid
        );
        evaluateNews(mostRecentlyDeployed, newsId, evaluation, confidence);
    }
}

contract GetNewsValidation is Script {
    function getNewsValidation(
        address mostRecentlyDeployed,
        uint newsId
    ) public returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        vm.startBroadcast();
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(mostRecentlyDeployed));
        (
            status,
            finalEvaluation,
            evaluationsCount
        ) = newsEvaluation.getNewsValidation(newsId);
        vm.stopBroadcast();

        console.log("Status: %s", uint(status));
        console.log("Final Evaluation: %s, confidence: %s", finalEvaluation.evaluation, finalEvaluation.confidence);
        console.log("Evaluations Count: %s", evaluationsCount);
    }

    function run(uint newsId) external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsEvaluation",
            block.chainid
        );
        getNewsValidation(mostRecentlyDeployed, newsId);
    }
}
