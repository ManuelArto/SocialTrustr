// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {TrustToken} from "../../TrustToken.sol";
import "../types/DataTypes.sol";

library NewsEvaluationCalculator {

    function getFinalEvaluation(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken
    ) internal view returns (bool result, uint averageConfidence, bool valid) {
        DataTypes.Evaluation[] memory evaluations = _newsValidation.evaluations;

        (
            DataTypes.TrustScore memory trueScore,
            DataTypes.TrustScore memory falseScore
        ) = calculateScores(evaluations, _trustToken);

        if (trueScore.score == falseScore.score) {
            return (false, 0, false); // TIE
        }

        result = trueScore.score > falseScore.score;
        averageConfidence = result
            ? trueScore.totalConfidence / trueScore.votersLength
            : falseScore.totalConfidence / falseScore.votersLength;
        return (result, averageConfidence, true);
    }

    function calculateScores(
        DataTypes.Evaluation[] memory evaluations,
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

        for (uint i = 0; i < evaluations.length; i++) {
            uint weightedVote = _trustToken.s_trustness(
                evaluations[i].evaluator
            ) * evaluations[i].confidence;
            if (evaluations[i].evaluation) {
                incrementScore(
                    trueScore,
                    weightedVote,
                    evaluations[i].confidence
                );
            } else {
                incrementScore(
                    falseScore,
                    weightedVote,
                    evaluations[i].confidence
                );
            }
        }
    }

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