// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./libraries/Errors.sol";
import {console} from "forge-std/Script.sol";

contract NewsEvaluation {
    uint public constant DEADLINE = 24 hours;

    mapping(uint => DataTypes.NewsValidation) private s_newsValidations;

    /* Functions */

    function startNewsValidation(uint newsId) public {
        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];

        if (newsValidation.status != DataTypes.EvaluationStatus.NotStarted) {
            revert Errors.NewsEvaluation_NewsAlreadyValidated();
        }

        newsValidation.status = DataTypes.EvaluationStatus.Evaluating;
        newsValidation.initiator = msg.sender;
        newsValidation.deadline = DEADLINE;

        emit Events.NewsValidationStarted(newsId, msg.sender, DEADLINE);
    }

    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) public {
        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];

        if (newsValidation.status != DataTypes.EvaluationStatus.Evaluating) {
            revert Errors.NewsEvaluation_NewsValidationNotStarted();
        }

        newsValidation.evaluations[msg.sender] = DataTypes.Evaluation(
            evaluation,
            confidence
        );
        newsValidation.evaluationsCount += 1;

        emit Events.NewsEvaluated(
            newsId,
            msg.sender,
            evaluation,
            confidence,
            newsValidation.evaluationsCount
        );
    }

    /** Internal Functions */

    /** Getter Functions */
    function getNewsValidation(
        uint newsId
    ) public view returns (
        address,
        uint,
        DataTypes.EvaluationStatus,
        DataTypes.Evaluation memory,
        uint
    ) {
        DataTypes.NewsValidation storage newsValidation = s_newsValidations[
            newsId
        ];

        return (
            newsValidation.initiator,
            newsValidation.deadline,
            newsValidation.status,
            newsValidation.finalEvaluation,
            newsValidation.evaluationsCount
        );
    }
}
