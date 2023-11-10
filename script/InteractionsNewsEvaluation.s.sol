// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract NewsEvaluationInteractions is Script {
    function evaluateNews(
        address _contract,
        uint newsId,
        bool evaluation,
        uint confidence
    ) public startBroadcast {
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(_contract));
        newsEvaluation.evaluateNews(newsId, evaluation, confidence);
    }

    function getNewsValidation(address _contract, uint newsId) public startBroadcast returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(_contract));
        (
            status,
            finalEvaluation,
            evaluationsCount
        ) = newsEvaluation.getNewsValidation(newsId);

        console.log("Status: %s", uint(status));
        console.log("Final Evaluation: %s, confidence: %s", finalEvaluation.evaluation, finalEvaluation.confidence);
        console.log("Evaluations Count: %s", evaluationsCount);
    }

    /* OVERLOAD FUNCTIONS */
    
    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external startBroadcast {
        evaluateNews(getNewsEvaluationContract(), newsId, evaluation, confidence);
    }

    function getNewsValidation(uint newsId) external startBroadcast returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        return getNewsValidation(getNewsEvaluationContract(), newsId);
    }

    /* INTERNAL FUNCTIONS */

    function getNewsEvaluationContract() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsEvaluation",
            block.chainid
        );
        return mostRecentlyDeployed;
    }

    modifier startBroadcast {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
