// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract NewsEvaluationInteractions is Script {
    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external startBroadcast {
        NewsEvaluation newsEvaluation = getNewsEvaluationContract();
        newsEvaluation.evaluateNews(newsId, evaluation, confidence);
    }

    function getNewsValidation(uint newsId) public startBroadcast returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        NewsEvaluation newsEvaluation = getNewsEvaluationContract();
        (
            status,
            finalEvaluation,
            evaluationsCount
        ) = newsEvaluation.getNewsValidation(newsId);

        console.log("Status: %s", uint(status));
        console.log("Final Evaluation: %s, confidence: %s", finalEvaluation.evaluation, finalEvaluation.confidence);
        console.log("Evaluations Count: %s", evaluationsCount);
    }

    /* INTERNAL FUNCTIONS */

    function getNewsEvaluationContract() internal returns (NewsEvaluation) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsEvaluation",
            block.chainid
        );
        return NewsEvaluation(payable(mostRecentlyDeployed));
    }

    modifier startBroadcast {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
