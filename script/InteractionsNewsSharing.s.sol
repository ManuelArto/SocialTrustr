// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import "../src/libraries/types/DataTypes.sol";

contract NewsSharingInteractions is Script {
    function shareNews(
        address _contract,
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) public startBroadcast {
        NewsSharing newsSharing = NewsSharing(payable(_contract));
        uint newsId = newsSharing.createNews(title, ipfsCid, chatName, parentId);
        console.log("News ID: %s", newsId);
    }

    function getNews(address _contract, uint id) public startBroadcast returns(DataTypes.News memory news) {
        NewsSharing newsSharing = NewsSharing(payable(_contract));
        news = newsSharing.getNews(id);
        
        console.log("Sharer: %s", news.sharer);
        console.log("Title: %s", news.title);
        console.log("IPFS CID: %s", news.ipfsCid);
        console.log("Chat Name: %s", news.chatName);
        console.log("Is Forwarded: %s", news.isForwarded);
    }

    function getTotalNews(address _contract) public startBroadcast returns(uint length) {
        NewsSharing newsSharing = NewsSharing(payable(_contract));
        length = newsSharing.getTotalNews();
        
        console.log("Total News: %s", length);
    }

    /* OVERLOAD FUNCTIONS */

    function shareNews(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) external {
        shareNews(getNewsSharingAddress(), title, ipfsCid, chatName, parentId);
    }

    function getNews(uint id) external returns(DataTypes.News memory news) {
        return getNews(getNewsSharingAddress(), id);
    }

    function getTotalNews() external returns(uint length) {
        return getTotalNews(getNewsSharingAddress());
    }

    /* INTERNAL FUNCTIONS */

    function getNewsSharingAddress() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsSharing",
            block.chainid
        );
        return mostRecentlyDeployed;
    }

    modifier startBroadcast {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}