// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Errors {
    error NewsSharing_NoParentNewsWithThatId();

    error NewsEvaluation_NewsAlreadyValidated();
    error NewsEvaluation_NewsValidationNotStarted();
}
