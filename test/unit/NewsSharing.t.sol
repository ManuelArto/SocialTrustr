// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {NewsSharing} from "../../src/NewsSharing.sol";
import {DeployNewsSharing} from "../../script/DeployNewsSharing.s.sol";

contract NewsSharingTest is Test {
    NewsSharing newsSharing;

    address USER = makeAddr("user");

    function setUp() external {
        DeployNewsSharing deployer = new DeployNewsSharing();
        newsSharing = deployer.run();
    }

}
