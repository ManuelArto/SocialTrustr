// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Errors {
    error NewsSharing_NoParentNewsWithThatId();

    error NewsEvaluation_NewsValidationPeriodEnded();
    error NewsEvaluation_CannotEvaluateForwardedNews();
}
