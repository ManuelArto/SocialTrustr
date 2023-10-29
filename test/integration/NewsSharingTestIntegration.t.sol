// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployNewsSharing} from "../../script/DeployNewsSharing.s.sol";
import {ShareNews} from "../../script/Interactions.s.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";

contract IntegrationsTest is StdCheats, Test {
    NewsSharing public newsSharing;

    address public constant USER = address(1);

    function setUp() external {
        DeployNewsSharing deployer = new DeployNewsSharing();
        newsSharing = deployer.run();
    }

    function testUserCanShare() public {
    }
}