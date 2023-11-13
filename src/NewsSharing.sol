// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NewsEvaluation} from "./NewsEvaluation.sol";
import {TrustToken} from "./TrustToken.sol";
import "./libraries/types/DataTypes.sol";
import "./libraries/types/Events.sol";
import "./libraries/types/Errors.sol";

contract NewsSharing is Ownable {
    TrustToken private immutable i_trustToken;

    DataTypes.News[] private s_news;
    NewsEvaluation private s_newsEvaluation;

    /* Functions */

    constructor(TrustToken _trustToken) Ownable(msg.sender) {
        i_trustToken = _trustToken;
        s_news.push(DataTypes.News("", "", "", address(0), false, block.timestamp)); //* Act as father for new news
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

        i_trustToken.stakeTRS(msg.sender, address(s_newsEvaluation), i_trustToken.TRS_FOR_SHARING());

        DataTypes.News memory news = DataTypes.News(title, ipfsCid, chatName, msg.sender, parentId != 0, block.timestamp);
        s_news.push(news);

        // TODO: trigger evaluate news automatic function

        id = s_news.length - 1;
        emit Events.NewsCreated(id, msg.sender, title, ipfsCid, chatName, parentId);
    }

    function setNewsEvaluationContract(NewsEvaluation _newsEvaluation) external onlyOwner {
        s_newsEvaluation = _newsEvaluation;
    }

    /** Getter Functions */

    function getTotalNews() public view returns (uint lenght) {
        lenght = s_news.length - 1;
    }

    function getNews(uint index) public view returns (DataTypes.News memory news) {
        news = s_news[index];
    }

    function getSharerOf(uint index) public view returns (address sharer) {
        sharer = s_news[index].sharer;
    }

    function isForwarded(uint index) public view returns (bool forwarded) {
        forwarded = s_news[index].isForwarded;
    }
}
