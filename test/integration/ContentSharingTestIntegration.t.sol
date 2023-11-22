// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {ContentSharingInteractions} from "../../script/InteractionsContentSharing.s.sol";
import {ContentSharing} from "../../src/ContentSharing.sol";
import {ContentEvaluation} from "../../src/ContentEvaluation.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import "../../src/libraries/types/DataTypes.sol";

contract IntegrationsTest is StdCheats, Test {
    ContentSharing contentSharing;
    TrustToken trustToken;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (contentSharing, , trustToken, ) = deployer.run();
    }

    modifier getBadge() {
        vm.startPrank(address(msg.sender));
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        vm.stopPrank();
        _;
    }

    function testUserCanShareAndGetContent() public getBadge{
        ContentSharingInteractions contentSharingInteractions = new ContentSharingInteractions();

        contentSharingInteractions.shareContent(address(contentSharing), TITLE, IPFSCID, CHATNAME, 0);
        DataTypes.Content memory content = contentSharingInteractions.getContent(address(contentSharing), 1);

        assertEq(content.title, TITLE);
        assertEq(content.ipfsCid, IPFSCID);
        assertEq(content.chatName, CHATNAME);
        assertEq(content.sharer, msg.sender);
    }
}
