// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {ContentEvaluation} from "../src/ContentEvaluation.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import "../src/libraries/types/DataTypes.sol";

contract ContentEvaluationInteractions is Script {
    function evaluateContent(
        address _contract,
        uint contentId,
        bool evaluation,
        uint confidence
    ) public startBroadcast {
        ContentEvaluation contentEvaluation = ContentEvaluation(payable(_contract));
        contentEvaluation.evaluateContent(contentId, evaluation, confidence);
    }

    function getContentValidation(
        address _contract,
        uint contentId
    ) public startBroadcast returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        ContentEvaluation contentEvaluation = ContentEvaluation(payable(_contract));
        (status, finalEvaluation, evaluationsCount) = contentEvaluation
            .getContentValidation(contentId);

        console.log("Status: %s", uint(status));
        console.log(
            "Final Evaluation: %s, confidence: %s",
            finalEvaluation.evaluation,
            finalEvaluation.confidence
        );
        console.log("Evaluations Count: %s", evaluationsCount);
    }

    function closeContentValidation(
        address _contract,
        uint contentId
    ) public startBroadcast {
        ContentEvaluation contentEvaluation = ContentEvaluation(payable(_contract));
        (
            string memory response,
            bool evaluation,
            uint confidence,
            bool valid
        ) = contentEvaluation.closeContentValidation(contentId);

        console.log("Response: %s", response);
        console.log("Evaluation: %s", evaluation);
        console.log("Confidence: %s", confidence);
        console.log("Valid: %s", valid);
    }

    function checkContentValidation(
        address _contract,
        uint contentId
    ) public startBroadcast {
        ContentEvaluation contentEvaluation = ContentEvaluation(payable(_contract));
        bool closingContent = contentEvaluation.checkContentValidation(contentId);
        console.log("Closing Content: %s", closingContent);
    }

    /* OVERLOAD FUNCTIONS */

    function evaluateContent(
        uint contentId,
        bool evaluation,
        uint confidence
    ) external {
        evaluateContent(
            getContentEvaluationContract(),
            contentId,
            evaluation,
            confidence
        );
    }

    function getContentValidation(
        uint contentId
    ) external returns (
        DataTypes.EvaluationStatus status,
        DataTypes.FinalEvaluation memory finalEvaluation,
        uint evaluationsCount
    ) {
        return getContentValidation(getContentEvaluationContract(), contentId);
    }

    function closeContentValidation(
        uint contentId
    ) public {
        closeContentValidation(getContentEvaluationContract(), contentId);
    } 

    function checkContentValidation(
        uint contentId
    ) public {
        checkContentValidation(getContentEvaluationContract(), contentId);
    }         

    /* INTERNAL FUNCTIONS */

    function getContentEvaluationContract() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "ContentEvaluation",
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
