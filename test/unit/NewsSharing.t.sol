// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../../src/libraries/DataTypes.sol";
import "../../src/libraries/Events.sol";
import {Test, console} from "forge-std/Test.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {DeployNewsSharing} from "../../script/DeployNewsSharing.s.sol";

contract NewsSharingTest is Test {
    NewsSharing newsSharing;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";

    function setUp() external {
        DeployNewsSharing deployer = new DeployNewsSharing();
        newsSharing = deployer.run();
    }

    function testUserCanShareNews() public {
        uint id = newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);

        assertEq(id, 1);
    }

    function testUserCanReadNews() public {
        DataTypes.News memory news = newsSharing.getNews(0);

        assertEq(news.title, "");
        assertEq(news.ipfsCid, "");
        assertEq(news.chatName, "");
    }

    function testCorrectlyShareNews() public {
        newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
        DataTypes.News memory news = newsSharing.getNews(1);

        assertEq(news.title, TITLE);
        assertEq(news.ipfsCid, IPFSCID);
        assertEq(news.chatName, CHATNAME);
        assertEq(news.sharer, address(this));
    }

    function testEmitNewsCreated() public {
        vm.expectEmit();
        emit Events.NewsCreated(1, address(this), TITLE, IPFSCID, CHATNAME, 0);
        
        newsSharing.createNews(TITLE, IPFSCID, CHATNAME, 0);
    }
}
