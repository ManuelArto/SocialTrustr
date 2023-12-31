// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {SD59x18, sd, convert, intoUint256} from "@prb/math/SD59x18.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {TrustToken} from "../../TrustToken.sol";
import "../types/DataTypes.sol";

library TokenAndTrustLevelTuning {
    /**
     * @dev Returns the stake to the sharer and evaluators.
     * @param _sharer The address of the sharer.
     * @param _contentValidation The memory reference to the content validation data.
     * @param _trustToken The instance of the TrustToken contract.
     */
    function returnStake(
        address _sharer,
        DataTypes.ContentValidation memory _contentValidation,
        TrustToken _trustToken
    ) internal {
        _trustToken.unstakeTRS(_sharer, _trustToken.TRS_FOR_SHARING());

        // evaluators
        DataTypes.Evaluation[] memory evaluations = _contentValidation.evaluations;
        for (uint i = 0; i < evaluations.length; i++) {
            _trustToken.unstakeTRS(
                evaluations[i].evaluator,
                _trustToken.TRS_FOR_EVALUATION()
            );
        }
    }

    /**
     * @dev Tunes the trust level and trust token based on the content validation.
     * @param _sharer The address of the sharer.
     * @param _contentValidation The memory reference to the content validation data.
     * @param _trustToken The instance of the TrustToken contract.
     */
    function tuneTrustLevelAndTrustToken(
        address _sharer,
        DataTypes.ContentValidation memory _contentValidation,
        TrustToken _trustToken
    ) internal {
        uint entropy = calculateEntropy(_contentValidation);
        console.log("Entropy: ", entropy);
        calculateRewardsAndPunishments(
            _sharer,
            _contentValidation,
            _trustToken,
            entropy
        );
    }

    /**
     * @dev Calculates the entropy of the content validation.
     * @param _contentValidation The memory reference to the content validation data.
     * @return entropy The entropy value.
     */
    function calculateEntropy(
        DataTypes.ContentValidation memory _contentValidation
    ) internal pure returns (uint entropy) {
        (uint[3] memory probabilities, uint length) = getProbabilities(_contentValidation);

        // * 1e16 instead of 1e18 because should be in range 0-1 instead of 0-100
        int multiplier = 1e16;

        SD59x18[3] memory p_fixed;
        for (uint i = 0; i < length; i++) {
            p_fixed[i] = sd(int(probabilities[i]) * multiplier);
        }

        SD59x18 base_3 = sd(3 * 1e18);
        SD59x18 entropy_fixed; // -1 * (p1*log3(p1) + p2*log3(p2) + p3*log3(p3))

        for (uint i = 0; i < length; i++) {
            entropy_fixed = entropy_fixed.add(
                p_fixed[i].mul(logBase(base_3, p_fixed[i]))
            );
        }
        entropy_fixed = entropy_fixed.mul(sd(-1 * 1e18));

        entropy = intoUint256(entropy_fixed) / uint(multiplier);
    }

    /**
     * @dev Calculates rewards and punishments for a content validation.
     * @param _sharer The address of the sharer.
     * @param _contentValidation The memory reference to the content validation data.
     * @param _trustToken The instance of the TrustToken contract.
     * @param entropy The entropy value used in the calculations.
     * 
        TRS
        - Punishment: sum (Stake * Conf)
        - Reward: (Conf / Tot_Conf) * Punishment

        TRUSTLEVEL (Punishment molto più drastico che guadagno)
        - Punishment: AF * Conf * (1.0 - Entropy)
        - Reward: (100-AF) * Conf * (1.0 - Entropy)/2
    */
    function calculateRewardsAndPunishments(
        address _sharer,
        DataTypes.ContentValidation memory _contentValidation,
        TrustToken _trustToken,
        uint entropy
    ) internal {
        DataTypes.FinalEvaluation memory finalEvaluation = _contentValidation.finalEvaluation;
        DataTypes.Evaluation[] memory evaluations = _contentValidation.evaluations;

        uint totalConfidence = 0;
        uint trsPunishments;
        uint trsForSharing = _trustToken.TRS_FOR_SHARING();
        uint trsForEvaluation = _trustToken.TRS_FOR_EVALUATION();

        if (finalEvaluation.evaluation) {
            trsPunishments = 0;
            _trustToken.unstakeTRS(_sharer, trsForSharing);
        } else {
            trsPunishments = trsForSharing;
            _trustToken.transferFromStakeToAdmin(_sharer, trsForSharing);
        }

        // Sharer TrustLevel Tuning
        trustLevelTuning(_sharer, true, 100, finalEvaluation.evaluation, entropy, _trustToken);

        for (uint i = 0; i < evaluations.length; i++) {
            DataTypes.Evaluation memory userEvaluation = evaluations[i];

            trustLevelTuning(userEvaluation.evaluator, userEvaluation.evaluation, userEvaluation.confidence, finalEvaluation.evaluation, entropy, _trustToken);
            
            if (userEvaluation.evaluation == finalEvaluation.evaluation) {
                // TRS Reward
                totalConfidence += userEvaluation.confidence;
                _trustToken.unstakeTRS(userEvaluation.evaluator, trsForEvaluation);
            } else {
                // TRS Punishemnt
                uint trsLost = trsForEvaluation * userEvaluation.confidence / 1e2;
                _trustToken.unstakeTRS(userEvaluation.evaluator, (trsForEvaluation - trsLost));
                _trustToken.transferFromStakeToAdmin(userEvaluation.evaluator, trsLost);
                
                trsPunishments += trsLost;
            }
        }

        // TRS Reward
        distributeTRSReward(_sharer, evaluations, finalEvaluation.evaluation, trsPunishments, totalConfidence, _trustToken); 
    }
    
    /**
     * @dev Adjusts the trust level of a user based on their evaluation, confidence, entropy, and final evaluation.
     * @param _user The address of the user.
     * @param userEvaluation The user's evaluation.
     * @param confidence The confidence level of the evaluation.
     * @param finalEvaluation The final evaluation.
     * @param entropy The entropy value.
     * @param _trustToken The TrustToken contract instance.
    */
    function trustLevelTuning(address _user, bool userEvaluation, uint confidence, bool finalEvaluation, uint entropy, TrustToken _trustToken) internal {
        uint prevTrustLevel = _trustToken.getTrustLevel(_user);
        uint newTrustLevel = prevTrustLevel;
        if (userEvaluation == finalEvaluation) {
            uint reward = calculateTrustLevelReward(prevTrustLevel, confidence, entropy);
            newTrustLevel += reward;
        } else {
            uint punishment = calculateTrustLevelPunishment(prevTrustLevel, confidence, entropy);
            newTrustLevel -= punishment;
        }
        _trustToken.setTrustLevel(_user, newTrustLevel);
    }

    /**
     * @dev Calculates the reward based on trust level, confidence, and entropy
     * @param trustLevel The trust level of the evaluator
     * @param confidence The confidence of the evaluation
     * @param entropy The entropy of the evaluation
     * @return The reward amount
     */
    function calculateTrustLevelReward(
        uint trustLevel,
        uint confidence,
        uint entropy
    ) internal pure returns (uint) {
        return ((100 - trustLevel) * confidence * ((100 - entropy) / 2)) / 1e4;
    }

    /**
     * @dev Calculates the punishment based on trust level, confidence, and entropy
     * @param trustLevel The trust level of the evaluator
     * @param confidence The confidence of the evaluation
     * @param entropy The entropy of the evaluation
     * @return The punishment amount
     */
    function calculateTrustLevelPunishment(
        uint trustLevel,
        uint confidence,
        uint entropy
    ) internal pure returns (uint) {
        return (trustLevel * confidence * (100 - entropy)) / 1e4;
    }

    /**
     * @dev Distributes the TRS reward to the sharer and evaluators
     * @param _sharer The address of the sharer
     * @param _evaluations The array of evaluations
     * @param _finalEvaluation The final evaluation
     * @param _trsPunishment The total TRS punishment
     * @param totalConfidence The total confidence of the evaluations
     * @param _trustToken The TrustToken contract
     */
    function distributeTRSReward(
        address _sharer,
        DataTypes.Evaluation[] memory _evaluations,
        bool _finalEvaluation,
        uint _trsPunishment,
        uint totalConfidence,
        TrustToken _trustToken
    ) internal {
        uint totalTrsRewarded = 0;

        // Sharer Reward only if true content
        if (_finalEvaluation) {
            totalConfidence += 100;
            uint trsReward = (100 * _trsPunishment) / totalConfidence;
            totalTrsRewarded += trsReward;

            _trustToken.transfer(_sharer, trsReward);
        }

        for (uint i = 0; i < _evaluations.length; i++) {
            DataTypes.Evaluation memory evaluation = _evaluations[i];
            if (evaluation.evaluation == _finalEvaluation) {
                uint trsReward = (evaluation.confidence * _trsPunishment) / totalConfidence;
                _trustToken.transfer(_evaluations[i].evaluator, trsReward);
                totalTrsRewarded += trsReward;
            }
        }

        // TODO Decide what to do with remaming TRS:
            // 1. Redirect the remaining TRS reward to the Sharer if true content OR to funds
            // 2. Add decimals to TRS Token

        if (_finalEvaluation) {
            _trustToken.transfer(_sharer, _trsPunishment - totalTrsRewarded);
        } else {
            _trustToken.transfer(address(_trustToken), _trsPunishment - totalTrsRewarded);
        }
    }


    /**
     * @dev Calculates the probabilities for content validation
     * @param _contentValidation The ContentValidation struct
     * @return probabilities The array of probabilities [p1, p2, p3]
     * @return length The length of the probabilities array
     */
    function getProbabilities(
        DataTypes.ContentValidation memory _contentValidation
    ) internal pure returns (uint[3] memory probabilities, uint length) {
        DataTypes.Evaluation[] memory evaluations = _contentValidation.evaluations;

        for (uint i = 0; i < evaluations.length; i++) {
            if (evaluations[i].evaluation) {
                probabilities[0] += evaluations[i].confidence;
            } else {
                probabilities[1] += evaluations[i].confidence;
            }
        }

        probabilities[0] /= evaluations.length;
        probabilities[1] /= evaluations.length;
        probabilities[2] = 100 - (probabilities[0] + probabilities[1]);

        return (probabilities, probabilities[2] == 0 ? 2 : 3); // Should include p3 or not
    }

    function logBase(SD59x18 base, SD59x18 n) internal pure returns (SD59x18) {
        return n.log2().div(base.log2()); // log3(x) => log2(x) / log2(3);
    }
}
