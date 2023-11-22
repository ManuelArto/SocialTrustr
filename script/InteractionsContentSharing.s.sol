// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {ContentSharing} from "../src/ContentSharing.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import "../src/libraries/types/DataTypes.sol";

contract ContentSharingInteractions is Script {
    function shareContent(
        address _contract,
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) public startBroadcast {
        ContentSharing contentSharing = ContentSharing(payable(_contract));
        uint contentId = contentSharing.createContent(title, ipfsCid, chatName, parentId);
        console.log("Content ID: %s", contentId);
    }

    function getContent(address _contract, uint id) public startBroadcast returns(DataTypes.Content memory content) {
        ContentSharing contentSharing = ContentSharing(payable(_contract));
        content = contentSharing.getContent(id);
        
        console.log("Sharer: %s", content.sharer);
        console.log("Title: %s", content.title);
        console.log("IPFS CID: %s", content.ipfsCid);
        console.log("Chat Name: %s", content.chatName);
        console.log("Is Forwarded: %s", content.isForwarded);
    }

    function getTotalContent(address _contract) public startBroadcast returns(uint length) {
        ContentSharing contentSharing = ContentSharing(payable(_contract));
        length = contentSharing.getTotalContent();
        
        console.log("Total Content: %s", length);
    }

    /* OVERLOAD FUNCTIONS */

    function shareContent(
        string calldata title,
        string calldata ipfsCid,
        string calldata chatName,
        uint parentId
    ) external {
        shareContent(getContentSharingAddress(), title, ipfsCid, chatName, parentId);
    }

    function getContent(uint id) external returns(DataTypes.Content memory content) {
        return getContent(getContentSharingAddress(), id);
    }

    function getTotalContent() external returns(uint length) {
        return getTotalContent(getContentSharingAddress());
    }

    /* INTERNAL FUNCTIONS */

    function getContentSharingAddress() internal returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "ContentSharing",
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