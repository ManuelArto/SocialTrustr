// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
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
        // uint entropy = calculateEntropy(_newsValidation);
        // calculateRewardsAndPunishments(_newsValidation, _trustToken, entropy);
    }

    function calculateRewardsAndPunishments(
        DataTypes.NewsValidation storage _newsValidation,
        TrustToken _trustToken,
        uint entropy
    ) internal view {
    }

    function calculateEntropy(
        // DataTypes.NewsValidation storage _newsValidation
    ) internal view returns (uint entropy) {
        uint p1 = 10;
        uint p2 = 62;
        uint p3 = (100 - p1 - p2);

        console.log(Math.log2(p1));
        console.log(logBase(3, p1));
        console.log(Math.log10(p1));
        console.log(Math.log10(p1) / Math.log10(3));

        entropy = 1;//-1 *int(p1*logBase(3, p1) + p2*logBase(3, p2) + p3*logBase(3, p3));
    }

    function logBase(uint base, uint n) internal pure returns (uint) {
        return Math.log2(n) / Math.log2(base);
    }

}

    // log3(x) => log2(x) * log2(3)
    // log3(x) => log2(x) / log2(3);


        // DataTypes.Evaluation[] memory _evaluations = _newsValidation.evaluations;

        // uint p1 = 0; // Confidence sum for true / evaluators
        // uint p2 = 0; // Confidence sum for false / evaluators

        // for (uint i = 0; i < _evaluations.length; i++) {
        //     if (_evaluations[i].evaluation) {
        //         p1 += _evaluations[i].confidence;
        //     } else {
        //         p2 += _evaluations[i].confidence;
        //     }
        // }

        // p1 /= _evaluations.length;
        // p2 /= _evaluations.length;
        // uint p3 = 100 - p1 - p2;