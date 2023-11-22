// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./DataTypes.sol";

library Events {
    event ContentCreated(
        uint indexed id,
        address indexed sender,
        string title,
        string ipfsCid,
        string chatName,
        uint parentContent
    );

    event ContentEvaluated(
        uint indexed id,
        DataTypes.EvaluationStatus status,
        bool evaluation,
        uint confidence,
        uint evaluationsCount
    );
}
