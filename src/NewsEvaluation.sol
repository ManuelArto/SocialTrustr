// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NewsSharing} from "./NewsSharing.sol";
import {TrustToken} from "./TrustToken.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./libraries/Errors.sol";

contract NewsEvaluation is Ownable {
    TrustToken private immutable i_trustToken;

    mapping(uint => DataTypes.NewsValidation) private s_newsValidations;
    NewsSharing private s_newsSharing;

    uint public constant DEADLINE = 24 hours;
    
    /* Functions */

    constructor(TrustToken _trustToken) Ownable(msg.sender) {
        i_trustToken = _trustToken;
    }

    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external {
        if (newsId == 0) {
            revert Errors.NewsEvaluation_InvalidNewsId();
        }
        if (s_newsSharing.isForwarded(newsId)) {
            revert Errors.NewsEvaluation_CannotEvaluateForwardedNews();
        }

        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];
        if (newsValidation.status != DataTypes.EvaluationStatus.Evaluating ) {
            revert Errors.NewsEvaluation_NewsValidationPeriodEnded();
        }

        i_trustToken.stakeTRS(msg.sender, address(this), i_trustToken.TRS_FOR_EVALUATION());

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

    function setNewsSharingContract(NewsSharing _newsSharing) external onlyOwner {
        s_newsSharing = _newsSharing;
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
