// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NewsSharing} from "./NewsSharing.sol";
import {TrustToken} from "./TrustToken.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./libraries/Errors.sol";

contract NewsEvaluation {
    TrustToken private immutable i_trustToken;
    NewsSharing private immutable i_newsSharing;

    uint public constant DEADLINE = 24 hours;

    mapping(uint => DataTypes.NewsValidation) private s_newsValidations;

    /* Functions */

    constructor(TrustToken _trustToken, NewsSharing _newsSharing) {
        i_trustToken = _trustToken;
        i_newsSharing = _newsSharing;
    }

    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external {
        if (i_newsSharing.isForwarded(newsId)) {
            revert Errors.NewsEvaluation_CannotEvaluateForwardedNews();
        }

        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];
        if (newsValidation.status != DataTypes.EvaluationStatus.NotVerified ) {
            revert Errors.NewsEvaluation_NewsValidationPeriodEnded();
        }

        newsValidation.evaluations.push(
            DataTypes.Evaluation(msg.sender, evaluation, confidence)
        );

        emit Events.NewsEvaluated(
            newsId,
            msg.sender,
            evaluation,
            confidence,
            newsValidation.evaluations.length
        );
    }

    /** Getter Functions */

    function getNewsValidation(
        uint newsId
    ) public view returns (DataTypes.EvaluationStatus, DataTypes.FinalEvaluation memory, uint) {
        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];

        return (
            newsValidation.status,
            newsValidation.finalEvaluation,
            newsValidation.evaluations.length
        );
    }
}
