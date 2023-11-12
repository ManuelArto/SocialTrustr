// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {NewsSharingInteractions} from "../../script/InteractionsNewsSharing.s.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import "../../src/libraries/types/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    NewsSharing newsSharing;
    TrustToken trustToken;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, , trustToken, ) = deployer.run();
    }

    modifier getBadge() {
        vm.startPrank(address(msg.sender));
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        vm.stopPrank();
        _;
    }

    function testUserCanShareAndGetNews() public getBadge{
        NewsSharingInteractions newsSharingInteractions = new NewsSharingInteractions();

        newsSharingInteractions.shareNews(address(newsSharing), TITLE, IPFSCID, CHATNAME, 0);
        DataTypes.News memory news = newsSharingInteractions.getNews(address(newsSharing), 1);

        assertEq(news.title, TITLE);
        assertEq(news.ipfsCid, IPFSCID);
        assertEq(news.chatName, CHATNAME);
        assertEq(news.sharer, msg.sender);
    }
}
