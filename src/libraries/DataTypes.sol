// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library DataTypes {

    struct News {
        string title;
        string ipfsCid;
        string chatName;
        address sharer;
        bool isForwarded;
        uint timestamp;
    }

    enum EvaluationStatus {
        Evaluating,
        NotVerified,
        Evaluated
    }

    struct FinalEvaluation {
        bool evaluation;
        uint confidence;
    }

    struct Evaluation {
        address evaluator;
        bool evaluation;
        uint confidence;
    }

    struct NewsValidation {
        EvaluationStatus status;
        FinalEvaluation finalEvaluation;
        Evaluation[] evaluations;
    }
   
}
