// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./DataTypes.sol";

library Events {
    event NewsCreated(
        uint indexed id,
        address indexed sender,
        string title,
        string ipfsCid,
        string chatName,
        uint parentNews
    );

    event NewsEvaluated(
        uint indexed id,
        DataTypes.EvaluationStatus status,
        bool evaluation,
        uint confidence,
        uint evaluationsCount
    );
}
