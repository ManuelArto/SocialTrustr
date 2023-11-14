// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import "../../src/libraries/types/DataTypes.sol";
import "../../src/libraries/types/Events.sol";

contract NewsEvaluationTest is Test {
    NewsEvaluation newsEvaluation;
    NewsSharing newsSharing;
    TrustToken trustToken;
    HelperConfig helperConfig;
    
    uint deadline;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    address[5] USERS = [ makeAddr("user1"), makeAddr("user2"), makeAddr("user3"), makeAddr("user4"), makeAddr("user5")];

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, newsEvaluation, trustToken, helperConfig) = deployer.run();
        (, deadline) = helperConfig.activeNetworkConfig();

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
        vm.warp(deadline*2);

        (string memory response, bool evaluation, uint confidence, bool valid) = newsEvaluation.closeNewsValidation(newsId);
        
        console.log("Response: ", response);
        console.log("Evaluation: %s, Confidence: %s, Valid: %s", evaluation, confidence, valid);
        assertEq(evaluation, true);
        assertEq(confidence, 90);
        assertEq(valid, true);

        // Read trustLevels and trustTokens
        for (uint i = 0; i < USERS.length; i++) {
            console.log("[USER%s] TrustLevel: %s, TRS: %s", i+1, trustToken.getTrustLevel(USERS[i]), trustToken.balanceOf(USERS[i]));
        }

        console.log("FUNDS TRS: %s", trustToken.getFundsTRS());
        console.log("NewsEvaluation TRS: %s", trustToken.balanceOf(address(newsEvaluation)));

        assertEq(trustToken.getTrustLevel(USERS[0]), 51);
        assertEq(trustToken.getTrustLevel(USERS[1]), 51);
        assertEq(trustToken.getTrustLevel(USERS[2]), 51);
        assertEq(trustToken.getTrustLevel(USERS[3]), 48);
        assertEq(trustToken.getTrustLevel(USERS[4]), 48);

        assertEq(trustToken.balanceOf(USERS[0]), 555);
        assertEq(trustToken.balanceOf(USERS[1]), 553);
        assertEq(trustToken.balanceOf(USERS[2]), 542);
        assertEq(trustToken.balanceOf(USERS[3]), 430);
        assertEq(trustToken.balanceOf(USERS[4]), 420);
        assertEq(trustToken.balanceOf(address(newsEvaluation)), 0);
        assertEq(trustToken.getFundsTRS(), 0);

        vm.stopPrank();
    }

}
