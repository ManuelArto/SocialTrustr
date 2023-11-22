// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {ContentEvaluationInteractions} from "../../script/InteractionsContentEvaluation.s.sol";
import {ContentEvaluation} from "../../src/ContentEvaluation.sol";
import {ContentSharing} from "../../src/ContentSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import "../../src/libraries/types/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    ContentEvaluation contentEvaluation;
    ContentSharing contentSharing;
    TrustToken trustToken;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    uint public constant DEADLINE = 24 hours;
    bool public constant EVALUATION = true;
    uint public constant CONFIDENCE = 10;

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (contentSharing, contentEvaluation, trustToken, ) = deployer.run();
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
    }

    uint contentId;
    modifier shareContent() {
        contentId = contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);
        _;
    }

    modifier getBadge() {
        vm.startPrank(address(msg.sender));
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        vm.stopPrank();
        _;
    }

    function testUserCanEvaluateAndGetContentValidation() public getBadge shareContent  {
        ContentEvaluationInteractions contentEvaluationInteractions = new ContentEvaluationInteractions();

        contentEvaluationInteractions.evaluateContent(address(contentEvaluation), contentId, EVALUATION, CONFIDENCE);
        (
            DataTypes.EvaluationStatus status,
            DataTypes.FinalEvaluation memory finalEvaluation,
            uint evaluationsCount
        ) = contentEvaluationInteractions.getContentValidation(address(contentEvaluation), contentId);

        assertEq(uint(status), uint(DataTypes.EvaluationStatus.Evaluating));
        assertEq(finalEvaluation.evaluation, false);
        assertEq(finalEvaluation.confidence, 0);
        assertEq(evaluationsCount, 1);
    }
}
