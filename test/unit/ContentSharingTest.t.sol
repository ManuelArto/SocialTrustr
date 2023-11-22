// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {ContentSharing} from "../../src/ContentSharing.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import "../../src/libraries/types/DataTypes.sol";
import "../../src/libraries/types/Events.sol";

contract ContentSharingTest is Test {
    TrustToken trustToken;
    ContentSharing contentSharing;

    string public constant TITLE = "TITLE";
    string public constant IPFSCID = "123456";
    string public constant CHATNAME = "CHATNAME";

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (contentSharing, , trustToken, ) = deployer.run();
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
    }

    function testUserCanShareContent() public {
        uint id = contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);

        assertEq(id, 1);
    }

    function testUserCanReadContent() public {
        DataTypes.Content memory content = contentSharing.getContent(0);

        assertEq(content.title, "");
        assertEq(content.ipfsCid, "");
        assertEq(content.chatName, "");
    }

    function testUserCanGetTotalContent() public {
        uint id = contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);
        assertEq(id, 1);

        uint length = contentSharing.getTotalContent();
        assertEq(length, 1);
    }

    function testCorrectlyShareContent() public {
        contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);
        DataTypes.Content memory content = contentSharing.getContent(1);

        assertEq(content.title, TITLE);
        assertEq(content.ipfsCid, IPFSCID);
        assertEq(content.chatName, CHATNAME);
        assertEq(content.sharer, address(this));
    }

    function testEmitContentCreated() public {
        vm.expectEmit();
        emit Events.ContentCreated(1, address(this), TITLE, IPFSCID, CHATNAME, 0);
        
        contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 0);
    }

    function testUserCannotShareContentWithNoParentContent() public {
        vm.expectRevert();
        contentSharing.createContent(TITLE, IPFSCID, CHATNAME, 1);
    }
}
