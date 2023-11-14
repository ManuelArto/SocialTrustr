// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


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
        Evaluated,
        NotVerified_NotEnoughVotes,
        NotVerified_EvaluationEndedInATie
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

    struct TrustScore {
        bool evaluation;
        uint score;
        uint totalConfidence;
        uint votersLength;
    }
   
}
