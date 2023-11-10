// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract NewsSharingInteractions is Script {
    function shareNews(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) public startBroadcast {
        NewsSharing newsSharing = getNewsSharingContract();
        uint newsId = newsSharing.createNews(title, ipfsCid, chatName, parentId);
        console.log("News ID: %s", newsId);
    }

    function getNews(uint id) public startBroadcast returns(DataTypes.News memory news) {
        NewsSharing newsSharing = getNewsSharingContract();
        news = newsSharing.getNews(id);
        
        console.log("Sharer: %s", news.sharer);
        console.log("Title: %s", news.title);
        console.log("IPFS CID: %s", news.ipfsCid);
        console.log("Chat Name: %s", news.chatName);
        console.log("Is Forwarded: %s", news.isForwarded);
    }

    function getTotalNews() public startBroadcast returns(uint length) {
        NewsSharing newsSharing = getNewsSharingContract();
        length = newsSharing.getTotalNews();
        
        console.log("Total News: %s", length);
    }

    /* INTERNAL FUNCTIONS */

    function getNewsSharingContract() internal returns (NewsSharing) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsSharing",
            block.chainid
        );
        return NewsSharing(payable(mostRecentlyDeployed));
    }

    modifier startBroadcast {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}