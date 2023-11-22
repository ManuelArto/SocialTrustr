// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {ContentEvaluation} from "../../src/ContentEvaluation.sol";
import {ContentSharing} from "../../src/ContentSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import "../../src/libraries/types/DataTypes.sol";
import "../../src/libraries/types/Events.sol";

contract ContentEvaluationTest is Test {
    ContentEvaluation contentEvaluation;
    ContentSharing contentSharing;
    TrustToken trustToken;
    HelperConfig helperConfig;
    
    uint deadline;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    address[5] USERS = [ makeAddr("user1"), makeAddr("user2"), makeAddr("user3"), makeAddr("user4"), makeAddr("user5")];

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (contentSharing, contentEvaluation, trustToken, helperConfig) = deployer.run();
        (, deadline) = helperConfig.activeNetworkConfig();

        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        for (uint i = 0; i < USERS.length; i++) {
            vm.deal(USERS[i], 1000 ether);
            vm.startPrank(USERS[i]);
            trustToken.buyBadge{value: trustToken.getBadgePrice()}();
            vm.stopPrank();
        }
    }

    uint contentId;
    modifier shareContent() {
        vm.startPrank(USERS[0]);
        contentId = contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);
        vm.stopPrank();
        _;
    }

    function testUserCanEvaluateContent() public shareContent {
        contentEvaluation.evaluateContent(contentId, true, 50);
    }

    function testUserCannotEvaluateContentIfNotEvaluationTime() public {
    }

    function testGetFinalEvaluationAndTuneTrustLevelAndTrustToken() public shareContent {
        vm.prank(USERS[1]);
        contentEvaluation.evaluateContent(contentId, true, 100);
        vm.prank(USERS[2]);
        contentEvaluation.evaluateContent(contentId, true, 80);
        vm.prank(USERS[3]);
        contentEvaluation.evaluateContent(contentId, false, 70);
        vm.prank(USERS[4]);
        contentEvaluation.evaluateContent(contentId, false, 80);

        vm.startPrank(address(contentEvaluation));
        vm.warp(deadline*2);

        (string memory response, bool evaluation, uint confidence, bool valid) = contentEvaluation.closeContentValidation(contentId);
        
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
        console.log("ContentEvaluation TRS: %s", trustToken.balanceOf(address(contentEvaluation)));

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
        assertEq(trustToken.balanceOf(address(contentEvaluation)), 0);
        assertEq(trustToken.getFundsTRS(), 0);

        vm.stopPrank();
    }

}
