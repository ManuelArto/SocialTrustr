// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


library Errors {
    error NewsSharing_NoParentNewsWithThatId();

    error NewsEvaluation_InvalidNewsId();
    error NewsEvaluation_NewsValidationPeriodEnded();
    error NewsEvaluation_CannotEvaluateForwardedNews();
    error NewsEvaluation_UpkeepNotNeeded();

    error TrustToken_UserAlreadyHasBadge();
    error TrustToken_NotEnoughETH(uint);
    error TrustToken_NotEnoughTRS(uint);
    error TrustToken_UserIsBlacklisted();
    error TrustToken_UserHasNoBadge();
    error TrustToken_OnlyAdmins();
}
