// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TrustToken} from "./TrustToken.sol";
import "./libraries/types/DataTypes.sol";
import "./libraries/types/Events.sol";
import "./libraries/types/Errors.sol";

contract ContentSharing is Ownable {
    TrustToken private immutable i_trustToken;

    DataTypes.Content[] private s_content;

    /* Functions */

    constructor(TrustToken _trustToken) Ownable(msg.sender) {
        i_trustToken = _trustToken;
        s_content.push(DataTypes.Content("", "", "", address(0), false, block.timestamp)); //* Act as father for new content
    }

    function createContent(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) external returns (uint id) {
        if (parentId >= s_content.length) {
            revert Errors.ContentSharing_NoParentContentWithThatId();
        }

        i_trustToken.stakeTRS(msg.sender, i_trustToken.TRS_FOR_SHARING());

        DataTypes.Content memory content = DataTypes.Content(
            title,
            ipfsCid,
            chatName,
            msg.sender,
            parentId != 0,
            block.timestamp
        );
        s_content.push(content);

        id = s_content.length - 1;
        emit Events.ContentCreated(id, msg.sender, title, ipfsCid, chatName, parentId);
    }

    /** Getter Functions */

    function getTotalContent() public view returns (uint lenght) {
        lenght = s_content.length - 1;
    }

    function getContent(uint index) public view returns (DataTypes.Content memory content) {
        content = s_content[index];
    }

    function getSharerOf(uint index) public view returns (address sharer) {
        sharer = s_content[index].sharer;
    }

    function isForwarded(uint index) public view returns (bool forwarded) {
        forwarded = s_content[index].isForwarded;
    }
}
