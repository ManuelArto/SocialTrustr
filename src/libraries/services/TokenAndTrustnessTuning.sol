// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {SD59x18, sd, convert, intoUint256} from "@prb/math/SD59x18.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {TrustToken} from "../../TrustToken.sol";
import "../types/DataTypes.sol";

library TokenAndTrustnessTuning {
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

    function calculateRewardsAndPunishments(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken,
        uint entropy
    ) internal view {
    }

    function calculateEntropy(
        DataTypes.NewsValidation storage _newsValidation
    ) internal view returns (uint entropy) {
        (uint[3] memory probabilities, uint lenght) = getProbabilities(_newsValidation);

        // * 1e16 instead of 1e18 because should be in range 0-1 instead of 0-100
        int multiplier = 1e16;

        SD59x18[3] memory p_fixed;
        for (uint i = 0; i < lenght; i++) {
            p_fixed[i] = sd(int(probabilities[i])*multiplier);
        }

        SD59x18 base_3 = sd(3*1e18);
        SD59x18 entropy_fixed; // -1 * (p1*log3(p1) + p2*log3(p2) + p3*log3(p3))
        
        for (uint i = 0; i < lenght; i++) {
            entropy_fixed = entropy_fixed.add(
                p_fixed[i].mul(logBase(base_3, p_fixed[i]))
            );
        }
        entropy_fixed = entropy_fixed.mul(sd(-1*1e18));

        entropy = intoUint256(entropy_fixed) / uint(multiplier);
        console.log(entropy);
    }

    function getProbabilities(
        DataTypes.NewsValidation storage _newsValidation
    ) internal view returns (uint[3] memory probabilities, uint lenght) {
        DataTypes.Evaluation[] memory _evaluations = _newsValidation.evaluations;

        for (uint i = 0; i < _evaluations.length; i++) {
            if (_evaluations[i].evaluation) {
                probabilities[0] += _evaluations[i].confidence;
            } else {
                probabilities[1] += _evaluations[i].confidence;
            }
        }

        probabilities[0] /= _evaluations.length;
        probabilities[1] /= _evaluations.length;
        probabilities[2] = 100 - (probabilities[0] + probabilities[1]);

        return (probabilities, probabilities[2] == 0 ? 2 : 3); // Should include p3 or not

    }

    function logBase(SD59x18 base, SD59x18 n) internal pure returns (SD59x18) {
        return n.log2().div(base.log2()); // log3(x) => log2(x) / log2(3);
    }

}