// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./libraries/Errors.sol";
import {console} from "forge-std/Script.sol";

contract NewsSharing {
    DataTypes.News[] private s_news;

    /* Functions */

    constructor() {
        s_news.push(DataTypes.News("", "", "", address(0), false)); // Act as father for new news
    }

    function createNews(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) external returns (uint id) {
        if (parentId >= s_news.length) {
            revert Errors.NewsSharing_NoParentNewsWithThatId();
        }

        DataTypes.News memory news = DataTypes.News(title, ipfsCid, chatName, msg.sender, parentId != 0);
        s_news.push(news);

        id = s_news.length - 1;
        emit Events.NewsCreated(id, msg.sender, title, ipfsCid, chatName, parentId);
    }

    /** Getter Functions */

    function getTotalNews() public view returns (uint lenght) {
        lenght = s_news.length - 1;
    }

    function getNews(uint index) public view returns (DataTypes.News memory news) {
        news = s_news[index];
    }

    function isForwarded(uint index) public view returns (bool forwarded) {
        forwarded = s_news[index].isForwarded;
    }
}
