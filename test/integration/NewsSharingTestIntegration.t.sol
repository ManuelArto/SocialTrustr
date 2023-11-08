// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {ShareNews, GetNews} from "../../script/InteractionsNewsSharing.s.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import "../../src/libraries/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    NewsSharing public newsSharing;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (newsSharing, , ) = deployer.run();
    }

    function testUserCanShareAndGetNews() public {
        ShareNews shareNews = new ShareNews();
        shareNews.shareNews(address(newsSharing), TITLE, IPFSCID, CHATNAME, 0);

        GetNews getNews = new GetNews();
        DataTypes.News memory news = getNews.getNews(address(newsSharing), 1);

        assertEq(news.title, TITLE);
        assertEq(news.ipfsCid, IPFSCID);
        assertEq(news.chatName, CHATNAME);
        assertEq(news.sharer, msg.sender);
    }
}