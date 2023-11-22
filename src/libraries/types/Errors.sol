// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


library Errors {
    error ContentSharing_NoParentContentWithThatId();

    error ContentEvaluation_InvalidContentId();
    error ContentEvaluation_ContentValidationPeriodEnded();
    error ContentEvaluation_CannotEvaluateForwardedContent();
    error ContentEvaluation_UpkeepNotNeeded();
    error ContentEvaluation_AlreadyVoted();
    error ContentEvaluation_AuthorCannotVote();

    error TrustToken_UserAlreadyHasBadge();
    error TrustToken_NotEnoughETH(uint);
    error TrustToken_NotEnoughTRS(uint);
    error TrustToken_UserIsBlacklisted();
    error TrustToken_UserHasNoBadge();
    error TrustToken_OnlyAdmins();
}
