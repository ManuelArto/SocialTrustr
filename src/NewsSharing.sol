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
        s_news.push(DataTypes.News("", "", "", address(0))); // Act as father for new news
    }

    function createNews(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) public returns (uint id) {
        if (parentId >= s_news.length) {
            revert Errors.NewsSharing_NoParentNewsWithThatId();
        }

        DataTypes.News memory news = DataTypes.News(title, ipfsCid, chatName, msg.sender);
        s_news.push(news);

        id = s_news.length - 1;
        emit Events.NewsCreated(id, msg.sender, title, ipfsCid, chatName, parentId);
    }

    /** Internal Functions */

    /** Getter Functions */

    function getTotalNews() public view returns (uint lenght) {
        lenght = s_news.length - 1;
    }

    function getNews(uint index) public view returns (DataTypes.News memory news) {
        news = s_news[index];
    }
}
