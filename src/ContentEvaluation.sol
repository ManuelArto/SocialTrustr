// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContentSharing} from "./ContentSharing.sol";
import {TrustToken} from "./TrustToken.sol";
import {ContentEvaluationCalculator} from "./libraries/services/ContentEvaluationCalculator.sol";
import {TokenAndTrustLevelTuning} from "./libraries/services/TokenAndTrustLevelTuning.sol";
import "./libraries/types/DataTypes.sol";
import "./libraries/types/Events.sol";
import "./libraries/types/Errors.sol";

contract ContentEvaluation is Ownable {
    TrustToken private immutable i_trustToken;
    uint public immutable i_deadline;

    mapping(uint => DataTypes.ContentValidation) private s_contentValidations;
    mapping (uint => mapping (address => bool)) private s_usersHasVoted;
    ContentSharing private s_contentSharing;

    
    /* Functions */

    constructor(TrustToken _trustToken, uint _deadline) Ownable(msg.sender) {
        i_trustToken = _trustToken;
        i_deadline = _deadline;
    }

    modifier validContent(uint contentId) {
        if (contentId == 0 || contentId > s_contentSharing.getTotalContent()) {
            revert Errors.ContentEvaluation_InvalidContentId();
        }
        _;
    }

    function evaluateContent(
        uint contentId,
        bool evaluation,
        uint confidence
    ) external validContent(contentId) {
        if (msg.sender == s_contentSharing.getSharerOf(contentId)) {
            revert Errors.ContentEvaluation_AuthorCannotVote();
        }
        if (s_usersHasVoted[contentId][msg.sender]) {
            revert Errors.ContentEvaluation_AlreadyVoted();
        }
        if (s_contentSharing.isForwarded(contentId)) {
            revert Errors.ContentEvaluation_CannotEvaluateForwardedContent();
        }

        DataTypes.ContentValidation storage contentValidation = s_contentValidations[contentId];
        if (contentValidation.status != DataTypes.EvaluationStatus.Evaluating ) {
            revert Errors.ContentEvaluation_ContentValidationPeriodEnded();
        }

        i_trustToken.stakeTRS(msg.sender, i_trustToken.TRS_FOR_EVALUATION());
        
        s_usersHasVoted[contentId][msg.sender] = true;
        contentValidation.evaluations.push(
            DataTypes.Evaluation(msg.sender, evaluation, confidence)
        );
    }

    function checkContentValidation(uint contentId) public validContent(contentId) view returns (bool upkeepNeeded) {
        DataTypes.Content memory content = s_contentSharing.getContent(contentId);

        bool isEvaluating = s_contentValidations[contentId].status == DataTypes.EvaluationStatus.Evaluating;
        bool timePassed = block.timestamp - content.timestamp >= i_deadline;

        upkeepNeeded = (isEvaluating && timePassed);
        return upkeepNeeded;
    }

    function closeContentValidation(uint contentId) external validContent(contentId) returns (string memory response, bool evaluation, uint confidence, bool valid) {
        // Check if content is still in the validation period
        bool isUpkeepNeeded = checkContentValidation(contentId);
        if (!isUpkeepNeeded) {
            revert Errors.ContentEvaluation_UpkeepNotNeeded();
        }
        
        DataTypes.ContentValidation storage validation = s_contentValidations[contentId];
        address sharer = s_contentSharing.getSharerOf(contentId);
        uint evaluations = validation.evaluations.length;
        uint trustedUsers = i_trustToken.s_trustedUsers();

        // Check if there are enough evaluations to make a decision
        if (trustedUsers <= 1 || (evaluations < trustedUsers / 2)) {
            TokenAndTrustLevelTuning.returnStake(sharer, validation, i_trustToken);
            validation.status = DataTypes.EvaluationStatus.NotVerified_NotEnoughVotes;

            emit Events.ContentEvaluated(contentId, validation.status, false, 0, evaluations);
            return ("Evaluation failed: Not enough votes", false, 0, false);
        }

        (evaluation, confidence, valid) = ContentEvaluationCalculator.getFinalEvaluation(validation, i_trustToken);
        if (!valid) {
            TokenAndTrustLevelTuning.returnStake(sharer, validation, i_trustToken);
            validation.status = DataTypes.EvaluationStatus.NotVerified_EvaluationEndedInATie;

            emit Events.ContentEvaluated(contentId, validation.status, false, 0, evaluations);
            return ("Evaluation failed: Tie", false, 0, valid);
        }

        validation.finalEvaluation = DataTypes.FinalEvaluation(evaluation, confidence);
        validation.status = DataTypes.EvaluationStatus.Evaluated;
        TokenAndTrustLevelTuning.tuneTrustLevelAndTrustToken(sharer, validation, i_trustToken);

        emit Events.ContentEvaluated(contentId, validation.status, evaluation, confidence, evaluations);
        return ("Evaluated", evaluation, confidence, valid);
    }

    function setContentSharingContract(ContentSharing _contentSharing) external onlyOwner {
        s_contentSharing = _contentSharing;
    }

    /** Getter Functions */

    function getContentValidation(
        uint contentId
    ) public view returns (DataTypes.EvaluationStatus, DataTypes.FinalEvaluation memory, uint) {
        DataTypes.ContentValidation memory contentValidation = s_contentValidations[contentId];

        return (
            contentValidation.status,
            contentValidation.finalEvaluation,
            contentValidation.evaluations.length
        );
    }
}
