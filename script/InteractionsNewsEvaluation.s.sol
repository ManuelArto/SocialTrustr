// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {NewsEvaluation} from "../src/NewsEvaluation.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import "../src/libraries/types/DataTypes.sol";

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

    function getNewsValidation(
        address _contract,
        uint newsId
    ) public startBroadcast returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(_contract));
        (status, finalEvaluation, evaluationsCount) = newsEvaluation
            .getNewsValidation(newsId);

        console.log("Status: %s", uint(status));
        console.log(
            "Final Evaluation: %s, confidence: %s",
            finalEvaluation.evaluation,
            finalEvaluation.confidence
        );
        console.log("Evaluations Count: %s", evaluationsCount);
    }

    function closeNewsValidation(
        address _contract,
        uint newsId
    ) public startBroadcast {
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(_contract));
        (
            string memory response,
            bool evaluation,
            uint confidence,
            bool valid
        ) = newsEvaluation.closeNewsValidation(newsId);

        console.log("Response: %s", response);
        console.log("Evaluation: %s", evaluation);
        console.log("Confidence: %s", confidence);
        console.log("Valid: %s", valid);
    }

    function checkNewsValidation(
        address _contract,
        uint newsId
    ) public startBroadcast {
        NewsEvaluation newsEvaluation = NewsEvaluation(payable(_contract));
        bool closingNews = newsEvaluation.checkNewsValidation(newsId);
        console.log("Closing News: %s", closingNews);
    }

    /* OVERLOAD FUNCTIONS */

    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external {
        evaluateNews(
            getNewsEvaluationContract(),
            newsId,
            evaluation,
            confidence
        );
    }

    function getNewsValidation(
        uint newsId
    ) external returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        return getNewsValidation(getNewsEvaluationContract(), newsId);
    }

    function closeNewsValidation(
        uint newsId
    ) public {
        closeNewsValidation(getNewsEvaluationContract(), newsId);
    } 

    function checkNewsValidation(
        uint newsId
    ) public {
        checkNewsValidation(getNewsEvaluationContract(), newsId);
    }         

    /* INTERNAL FUNCTIONS */

    function getNewsEvaluationContract() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsEvaluation",
            block.chainid
        );
        return mostRecentlyDeployed;
    }

    modifier startBroadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
