// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {TrustToken} from "../TrustToken.sol";
import "./DataTypes.sol";

library NewsEvaluationCalculator {
    function returnStake(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken
    ) internal view {}

    function tuneTrustnessAndTrustToken(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken
    ) internal view {
        uint entropy = calculateEntropy(_newsValidation);
        calculateRewardsAndPunishments(_newsValidation, _trustToken, entropy);
    }

    function getFinalEvaluation(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken
    ) internal view returns (bool result, uint averageConfidence, bool valid) {
        DataTypes.Evaluation[] memory evaluations = _newsValidation.evaluations;

        (
            DataTypes.TrustScore trueScore,
            DataTypes.TrustScore falseScore
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

    function calculateEntropy(
        DataTypes.NewsValidation storage _newsValidation
    ) internal view returns (uint entropy) {
        DataTypes.Evaluation[] memory _evaluations = _newsValidation.evaluations;

        uint p1 = 0; // Confidence sum for true / evaluators
        uint p2 = 0; // Confidence sum for false / evaluators

        for (uint i = 0; i < _evaluations.length; i++) {
            if (_evaluations[i].evaluation) {
                p1 += _evaluations[i].confidence;
            } else {
                p2 += _evaluations[i].confidence;
            }
        }

        p1 /= _evaluations.length;
        p2 /= _evaluations.length;
        uint p3 = 100 - p1 - p2;

        // entropy = -(p1*logBase(3, p1) + p2*logBase(3, p2) + p3*logBase(3, p3));
    }

    function calculateRewardsAndPunishments(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken,
        uint entropy
    ) internal view {
        

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

    function logBase(uint base, uint n) internal pure returns (uint) {
        return Math.log2(n) / Math.log2(base);
    }
}
