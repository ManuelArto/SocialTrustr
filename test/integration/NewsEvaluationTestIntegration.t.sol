// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {StartNewsValidation, EvaluateNews, GetNewsValidation} from "../../script/InteractionsNewsEvaluation.s.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import "../../src/libraries/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    NewsEvaluation newsEvaluation;
    NewsSharing newsSharing;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    uint public constant DEADLINE = 24 hours;
    bool public constant EVALUATION = true;
    uint public constant CONFIDENCE = 10;

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, newsEvaluation) = deployer.run();
    }

    uint newsId;
    modifier shareNews() {
        newsId = newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
        _;
    }

    function testUserCanStartEvaluateAndGetNewsValidation() public shareNews {
        StartNewsValidation startNewsValidation = new StartNewsValidation();
        startNewsValidation.startNewsValidation(
            address(newsEvaluation),
            newsId
        );

        EvaluateNews evaluateNews = new EvaluateNews();
        evaluateNews.evaluateNews(address(newsEvaluation), newsId, EVALUATION, CONFIDENCE);

        GetNewsValidation getNewsValidation = new GetNewsValidation();
        (
            address initiator,
            uint deadline,
            DataTypes.EvaluationStatus status,
            DataTypes.Evaluation memory finalEvaluation,
            uint evaluationsCount
        ) = getNewsValidation.getNewsValidation(address(newsEvaluation), newsId);

        assertEq(initiator, msg.sender);
        assertEq(deadline, DEADLINE);
        assertEq(uint(status), uint(DataTypes.EvaluationStatus.Evaluating));
        assertEq(finalEvaluation.evaluation, false);
        assertEq(finalEvaluation.confidence, 0);
        assertEq(evaluationsCount, 1);
    }
}
