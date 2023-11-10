// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {NewsEvaluationInteractions} from "../../script/InteractionsNewsEvaluation.s.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import "../../src/libraries/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    NewsEvaluation newsEvaluation;
    NewsSharing newsSharing;
    TrustToken trustToken;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    uint public constant DEADLINE = 24 hours;
    bool public constant EVALUATION = true;
    uint public constant CONFIDENCE = 10;

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, newsEvaluation, trustToken) = deployer.run();
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
    }

    uint newsId;
    modifier shareNews() {
        newsId = newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
        _;
    }

    function testUserCanEvaluateAndGetNewsValidation() public shareNews {
        NewsEvaluationInteractions newsEvaluationInteractions = new NewsEvaluationInteractions();

        newsEvaluationInteractions.evaluateNews(newsId, EVALUATION, CONFIDENCE);
        (
            DataTypes.EvaluationStatus status,
            DataTypes.FinalEvaluation memory finalEvaluation,
            uint evaluationsCount
        ) = newsEvaluationInteractions.getNewsValidation(newsId);

        assertEq(uint(status), uint(DataTypes.EvaluationStatus.Evaluating));
        assertEq(finalEvaluation.evaluation, false);
        assertEq(finalEvaluation.confidence, 0);
        assertEq(evaluationsCount, 1);
    }
}
