// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {NewsSharing} from "../src/NewsSharing.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract ShareNews is Script {
    function shareNews(
        address mostRecentlyDeployed,
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) public {
        vm.startBroadcast();
        NewsSharing newsSharing = NewsSharing(payable(mostRecentlyDeployed));
        uint newsId = newsSharing.createNews(title, ipfsCid, chatName, parentId);
        vm.stopBroadcast();
        console.log("News ID: %s", newsId);
    }

    function run(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsSharing",
            block.chainid
        );
        shareNews(mostRecentlyDeployed, title, ipfsCid, chatName, parentId);
    }
}

contract GetNews is Script {
    function getNews(address mostRecentlyDeployed, uint id) public returns(DataTypes.News memory news) {
        vm.startBroadcast();
        NewsSharing newsSharing = NewsSharing(payable(mostRecentlyDeployed));
        news = newsSharing.getNews(id);
        vm.stopBroadcast();
        
        console.log("Sharer: %s", news.sharer);
        console.log("Title: %s", news.title);
        console.log("IPFS CID: %s", news.ipfsCid);
        console.log("Chat Name: %s", news.chatName);
    }

    function run(uint id) external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "NewsSharing",
            block.chainid
        );
        getNews(mostRecentlyDeployed, id);
    }
}
