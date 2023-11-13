// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import {TokenAndTrustLevelTuning} from "../../src/libraries/services/TokenAndTrustLevelTuning.sol";
import {NewsEvaluationCalculator} from "../../src/libraries/services/NewsEvaluationCalculator.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import "../../src/libraries/types/DataTypes.sol";
import "../../src/libraries/types/Events.sol";

contract NewsEvaluationTest is Test {
    NewsEvaluation newsEvaluation;
    NewsSharing newsSharing;
    TrustToken trustToken;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    uint public constant DEADLINE = 24 hours;
    address[5] USERS = [ makeAddr("user1"), makeAddr("user2"), makeAddr("user3"), makeAddr("user4"), makeAddr("user5")];

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, newsEvaluation, trustToken, ) = deployer.run();
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        for (uint i = 0; i < USERS.length; i++) {
            vm.deal(USERS[i], 1000 ether);
            vm.startPrank(USERS[i]);
            trustToken.buyBadge{value: trustToken.getBadgePrice()}();
            vm.stopPrank();
        }
    }

    uint newsId;
    modifier shareNews() {
        vm.startPrank(USERS[0]);
        newsId = newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
        vm.stopPrank();
        _;
    }

    function testUserCanEvaluateNews() public shareNews {
        vm.expectEmit();
        emit Events.NewsEvaluated(newsId, address(this), true, 50, 1);
        
        newsEvaluation.evaluateNews(newsId, true, 50);
    }

    function testUserCannotEvaluateNewsIfNotEvaluationTime() public {
    }

    function testGetFinalEvaluationAndTuneTrustLevelAndTrustToken() public shareNews {
        vm.prank(USERS[1]);
        newsEvaluation.evaluateNews(newsId, true, 100);
        vm.prank(USERS[2]);
        newsEvaluation.evaluateNews(newsId, true, 80);
        vm.prank(USERS[3]);
        newsEvaluation.evaluateNews(newsId, false, 70);
        vm.prank(USERS[4]);
        newsEvaluation.evaluateNews(newsId, false, 80);

        vm.startPrank(address(newsEvaluation));

         // TODO: should call newsvaluation.closeNewsValidation(newsId)

        DataTypes.NewsValidation memory newsValidation = newsEvaluation.getNewsValidationStruct(newsId);

        (bool evaluation, uint confidence, bool valid) = NewsEvaluationCalculator.getFinalEvaluation(newsValidation, trustToken);
        console.log("evaluation: %s, confidence: %s, valid: %s", evaluation, confidence, valid);
        assertEq(evaluation, true);
        assertEq(confidence, 90);
        assertEq(valid, true);

        newsValidation.finalEvaluation = DataTypes.FinalEvaluation(evaluation, confidence);
        TokenAndTrustLevelTuning.tuneTrustLevelAndTrustToken(newsSharing.getSharerOf(newsId), newsValidation, trustToken);

        // Read trustLevels and trustTokens
        for (uint i = 0; i < USERS.length; i++) {
            console.log("[USER%s] TrustLevel: %s, TRS: %s", i+1, trustToken.getTrustLevel(USERS[i]), trustToken.balanceOf(USERS[i]));
        }

        assertEq(trustToken.getTrustLevel(USERS[0]), 51);
        assertEq(trustToken.getTrustLevel(USERS[1]), 51);
        assertEq(trustToken.getTrustLevel(USERS[2]), 51);
        assertEq(trustToken.getTrustLevel(USERS[3]), 48);
        assertEq(trustToken.getTrustLevel(USERS[4]), 48);

        assertEq(trustToken.balanceOf(USERS[0]), 553);
        assertEq(trustToken.balanceOf(USERS[1]), 553);
        assertEq(trustToken.balanceOf(USERS[2]), 542);
        assertEq(trustToken.balanceOf(USERS[3]), 430);
        assertEq(trustToken.balanceOf(USERS[4]), 420);

        vm.stopPrank();
    }

}
