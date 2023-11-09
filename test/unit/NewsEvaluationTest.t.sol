// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../../src/libraries/DataTypes.sol";
import "../../src/libraries/Events.sol";
import {Test, console} from "forge-std/Test.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";

contract NewsEvaluationTest is Test {
    NewsEvaluation newsEvaluation;
    NewsSharing newsSharing;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";
    uint public constant DEADLINE = 24 hours;

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, newsEvaluation, ) = deployer.run();
    }

    uint newsId;
    modifier shareNews() {
        newsId = newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
        _;
    }

    function testUserCanEvaluateNews() public shareNews {
        vm.expectEmit();
        emit Events.NewsEvaluated(newsId, address(this), true, 50, 1);
        
        newsEvaluation.evaluateNews(newsId, true, 50);
    }

    function testUserCannotEvaluateNewsIfNotEvaluationTime() public shareNews {
    }
}
