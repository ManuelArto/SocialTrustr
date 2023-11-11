// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NewsSharing} from "./NewsSharing.sol";
import {TrustToken} from "./TrustToken.sol";
import {NewsEvaluationCalculator} from "./libraries/NewsEvaluationCalculator.sol";
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

    function checkNewsValidation(uint newsId) public view returns (bool upkeepNeeded) {
        DataTypes.News memory news = s_newsSharing.getNews(newsId);

        bool isEvaluating = s_newsValidations[newsId].status == DataTypes.EvaluationStatus.Evaluating;
        bool timePassed = block.timestamp - news.timestamp >= DEADLINE;

        upkeepNeeded = (isEvaluating && timePassed);
        return upkeepNeeded;

    }

    function closeNewsValidation(uint newsId) external returns (string memory response, bool evaluation, uint confidence, bool valid) {
        bool upkeepNeeded = checkNewsValidation(newsId);
        if (!upkeepNeeded) {
            revert Errors.NewsEvaluation_UpkeepNotNeeded();
        }
        
        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];

        bool hasMinimumVotes = newsValidation.evaluations.length > i_trustToken.trustedUsers() / 2;
        if (!hasMinimumVotes) {
            newsValidation.status = DataTypes.EvaluationStatus.NotVerified;
            response = "Evaluation failed: Not enough votes";
            NewsEvaluationCalculator.returnStake(newsValidation, i_trustToken);
            return (response, false, 0);
        }

        newsValidation.status = DataTypes.EvaluationStatus.Evaluated;
        (evaluation, confidence, valid) = NewsEvaluationCalculator.getFinalEvaluation(newsValidation, i_trustToken);
        if (!valid) {
            NewsEvaluationCalculator.returnStake(newsValidation, i_trustToken);
            newsValidation.status = DataTypes.EvaluationStatus.NotVerified;
            response = "Evaluation failed: Tie";
            return (response, false, 0);
        }

        newsValidation.finalEvaluation = DataTypes.FinalEvaluation(evaluation, confidence);
        NewsEvaluationCalculator.tuneTrustnessAndTrustToken(newsValidation, i_trustToken);

        response = "Evaluated";
        return (response, evaluation, confidence);
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
