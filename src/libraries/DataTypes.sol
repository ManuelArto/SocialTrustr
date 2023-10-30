// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library DataTypes {

    struct News {
        string title;
        string ipfsCid;
        string chatName;
        address sharer;
    }

    enum EvaluationStatus {
        NotStarted,
        NotVerified,
        Evaluating,
        Evaluated
    }

    struct Evaluation {
        bool evaluation;
        uint confidence;
    }

    struct NewsValidation {
        address initiator;
        uint deadline;
        EvaluationStatus status;
        Evaluation finalEvaluation;
        mapping (address => Evaluation) evaluations;
        uint evaluationsCount;
    }
   
}
