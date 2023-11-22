// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {TrustToken} from "../../TrustToken.sol";
import "../types/DataTypes.sol";

library ContentEvaluationCalculator {

    /**
     * @dev Get the final evaluation of content validation.
     * @param _contentValidation The memory struct containing the content validation data.
     * @param _trustToken The TrustToken contract instance.
     * @return result The final evaluation result (true or false).
     * @return averageConfidence The average confidence of the evaluations.
     * @return valid A boolean flag indicating if the evaluation is valid.
     */
    function getFinalEvaluation(
        DataTypes.ContentValidation memory _contentValidation,
        TrustToken _trustToken
    ) internal view returns (bool result, uint averageConfidence, bool valid) {
        DataTypes.Evaluation[] memory _evaluations = _contentValidation.evaluations;

        (
            DataTypes.TrustScore memory trueScore,
            DataTypes.TrustScore memory falseScore
        ) = calculateScores(_evaluations, _trustToken);

        if (trueScore.score == falseScore.score) {
            return (false, 0, false); // TIE
        }

        result = trueScore.score > falseScore.score;
        averageConfidence = result
            ? trueScore.totalConfidence / trueScore.votersLength
            : falseScore.totalConfidence / falseScore.votersLength;
        return (result, averageConfidence, true);
    }

    /**
     * @dev Calculate the trust scores based on the evaluations.
     * @param _evaluations The array of evaluations.
     * @param _trustToken The TrustToken contract instance.
     * @return trueScore The trust score for true evaluations.
     * @return falseScore The trust score for false evaluations.
     */
    function calculateScores(
        DataTypes.Evaluation[] memory _evaluations,
        TrustToken _trustToken
    )
        internal
        view
        returns (
            DataTypes.TrustScore memory trueScore,
            DataTypes.TrustScore memory falseScore
        )
    {
        trueScore = DataTypes.TrustScore(true, 0, 0, 0);
        falseScore = DataTypes.TrustScore(false, 0, 0, 0);

        for (uint i = 0; i < _evaluations.length; i++) {
            uint weightedVote = _trustToken.getTrustLevel(_evaluations[i].evaluator) * _evaluations[i].confidence;
            incrementScore(
                _evaluations[i].evaluation ? trueScore : falseScore,
                weightedVote,
                _evaluations[i].confidence
            );
        }
    }

    /**
     * @dev Increment the score based on the weighted vote and confidence.
     * @param score The trust score to increment.
     * @param weightedVote The weighted vote for the evaluation.
     * @param confidence The confidence of the evaluation.
     */
    function incrementScore(
        DataTypes.TrustScore memory score,
        uint weightedVote,
        uint confidence
    ) internal pure {
        score.score += weightedVote;
        score.totalConfidence += confidence;
        score.votersLength++;
    }
}