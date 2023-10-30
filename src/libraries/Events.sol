// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Events {
    event NewsCreated(
        uint indexed id,
        address indexed sender,
        string title,
        string ipfsCid,
        string chatName,
        uint parentNews
    );

    event NewsValidationStarted(
        uint indexed id,
        address indexed initiator,
        uint deadline
    );

    event NewsEvaluated(
        uint indexed id,
        address indexed evaluator,
        bool evaluation,
        uint confidence,
        uint evaluationsCount
    );
}
