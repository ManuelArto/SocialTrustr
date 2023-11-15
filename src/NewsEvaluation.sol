// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NewsSharing} from "./NewsSharing.sol";
import {TrustToken} from "./TrustToken.sol";
import {NewsEvaluationCalculator} from "./libraries/services/NewsEvaluationCalculator.sol";
import {TokenAndTrustLevelTuning} from "./libraries/services/TokenAndTrustLevelTuning.sol";
import "./libraries/types/DataTypes.sol";
import "./libraries/types/Events.sol";
import "./libraries/types/Errors.sol";

contract NewsEvaluation is Ownable {
    TrustToken private immutable i_trustToken;
    uint public immutable i_deadline;

    mapping(uint => DataTypes.NewsValidation) private s_newsValidations;
    mapping (uint => mapping (address => bool)) private s_usersHasVoted;
    NewsSharing private s_newsSharing;

    
    /* Functions */

    constructor(TrustToken _trustToken, uint _deadline) Ownable(msg.sender) {
        i_trustToken = _trustToken;
        i_deadline = _deadline;
    }

    modifier validNews(uint newsId) {
        if (newsId == 0 || newsId > s_newsSharing.getTotalNews()) {
            revert Errors.NewsEvaluation_InvalidNewsId();
        }
        _;
    }

    function evaluateNews(
        uint newsId,
        bool evaluation,
        uint confidence
    ) external validNews(newsId) {
        if (msg.sender == s_newsSharing.getSharerOf(newsId)) {
            revert Errors.NewsEvaluation_AuthorCannotVote();
        }
        if (s_usersHasVoted[newsId][msg.sender]) {
            revert Errors.NewsEvaluation_AlreadyVoted();
        }
        if (s_newsSharing.isForwarded(newsId)) {
            revert Errors.NewsEvaluation_CannotEvaluateForwardedNews();
        }

        DataTypes.NewsValidation storage newsValidation = s_newsValidations[newsId];
        if (newsValidation.status != DataTypes.EvaluationStatus.Evaluating ) {
            revert Errors.NewsEvaluation_NewsValidationPeriodEnded();
        }

        i_trustToken.stakeTRS(msg.sender, i_trustToken.TRS_FOR_EVALUATION());
        
        s_usersHasVoted[newsId][msg.sender] = true;
        newsValidation.evaluations.push(
            DataTypes.Evaluation(msg.sender, evaluation, confidence)
        );
    }

    function checkNewsValidation(uint newsId) public validNews(newsId) view returns (bool upkeepNeeded) {
        DataTypes.News memory news = s_newsSharing.getNews(newsId);

        bool isEvaluating = s_newsValidations[newsId].status == DataTypes.EvaluationStatus.Evaluating;
        bool timePassed = block.timestamp - news.timestamp >= i_deadline;

        upkeepNeeded = (isEvaluating && timePassed);
        return upkeepNeeded;
    }

    function closeNewsValidation(uint newsId) external validNews(newsId) returns (string memory response, bool evaluation, uint confidence, bool valid) {
        bool isUpkeepNeeded = checkNewsValidation(newsId);
        if (!isUpkeepNeeded) {
            revert Errors.NewsEvaluation_UpkeepNotNeeded();
        }
        
        DataTypes.NewsValidation storage validation = s_newsValidations[newsId];
        uint trustedUsers = i_trustToken.s_trustedUsers();

        // Check if there are enough evaluations to make a decision
        if (trustedUsers <= 1 || (validation.evaluations.length < trustedUsers / 2)) {
            validation.status = DataTypes.EvaluationStatus.NotVerified_NotEnoughVotes;
            TokenAndTrustLevelTuning.returnStake(s_newsSharing.getSharerOf(newsId), validation, i_trustToken);

            emit Events.NewsEvaluated(newsId, validation.status, false, 0, validation.evaluations.length);
            return ("Evaluation failed: Not enough votes", false, 0, false);
        }

        (evaluation, confidence, valid) = NewsEvaluationCalculator.getFinalEvaluation(validation, i_trustToken);
        console.log("Evaluation: ", evaluation);
        console.log("Confidence: ", confidence);
        console.log("Valid: ", valid);
        
        // Check if the evaluation is valid
        if (!valid) {
            TokenAndTrustLevelTuning.returnStake(s_newsSharing.getSharerOf(newsId), validation, i_trustToken);
            validation.status = DataTypes.EvaluationStatus.NotVerified_EvaluationEndedInATie;

            emit Events.NewsEvaluated(newsId, validation.status, false, 0, validation.evaluations.length);
            return ("Evaluation failed: Tie", false, 0, valid);
        }

        validation.finalEvaluation = DataTypes.FinalEvaluation(evaluation, confidence);
        validation.status = DataTypes.EvaluationStatus.Evaluated;
        TokenAndTrustLevelTuning.tuneTrustLevelAndTrustToken(s_newsSharing.getSharerOf(newsId), validation, i_trustToken);

        emit Events.NewsEvaluated(newsId, validation.status, evaluation, confidence, validation.evaluations.length);
        return ("Evaluated", evaluation, confidence, valid);
    }

    function setNewsSharingContract(NewsSharing _newsSharing) external onlyOwner {
        s_newsSharing = _newsSharing;
    }

    /** Getter Functions */

    function getNewsValidation(
        uint newsId
    ) public view returns (DataTypes.EvaluationStatus, DataTypes.FinalEvaluation memory, uint) {
        DataTypes.NewsValidation memory newsValidation = s_newsValidations[newsId];

        return (
            newsValidation.status,
            newsValidation.finalEvaluation,
            newsValidation.evaluations.length
        );
    }
}
