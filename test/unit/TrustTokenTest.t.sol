// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {TrustToken} from "../../src/TrustToken.sol";
import {NewsEvaluation} from "../../src/NewsEvaluation.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import "../../src/libraries/types/DataTypes.sol";
import "../../src/libraries/types/Events.sol";

contract TrustTokenTest is Test {
    NewsEvaluation newsEvaluation;
    TrustToken trustToken;

    address[5] USERS = [
        makeAddr("user1"),
        makeAddr("user2"),
        makeAddr("user3"),
        makeAddr("user4"),
        makeAddr("user5")
    ];

    function setUp() external {
        DeployScript deployer = new DeployScript();
        (, newsEvaluation, trustToken, ) = deployer.run();
        vm.deal(address(this), 1000 ether);
    }

    function testBuyBadge() external {
        // Test that a user can buy a badge and receive initial TRS tokens
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        assertEq(trustToken.balanceOf(address(this)), trustToken.INITIAL_TRS());
        assertEq(trustToken.s_trustLevel(address(this)), trustToken.INITIAL_TRUST_LEVEL());
        assertEq(trustToken.s_trustedUsers(), 1);
    }

    function testReceiveEthForTRS() external {
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        uint prevBalance = address(this).balance;
        trustToken.transfer(address(trustToken), trustToken.INITIAL_TRS());
        assertEq(address(this).balance, prevBalance + trustToken.convertTRStoETH(trustToken.INITIAL_TRS()));
        assertEq(trustToken.balanceOf(address(this)), 0);
    }

    function testBuyFromFunds() external {
        // Test that a user with a badge can buy TrustToken directly from contract funds
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();

        vm.startPrank(USERS[0]);
        vm.deal(USERS[0], 1000 ether);
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        trustToken.transfer(address(trustToken), trustToken.INITIAL_TRS());
        vm.stopPrank();
        uint fundsBefore = trustToken.getFundsTRS();

        trustToken.buyFromFunds{value: trustToken.convertTRStoETH(trustToken.INITIAL_TRS())}();
        assertEq(trustToken.balanceOf(address(this)), trustToken.INITIAL_TRS() + trustToken.INITIAL_TRS());
        assertEq(trustToken.getFundsTRS(), fundsBefore - trustToken.INITIAL_TRS());
    }

    function testStakeTRS() external {
        // Test that an admin can stake TRS tokens for a user
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        vm.prank(address(newsEvaluation));
        trustToken.stakeTRS(address(this), 10);
        assertEq(trustToken.s_staked(address(this)), 10);
    }

    function testTransferFromStakeToAdmin() external {
        // Test that an admin can transfer TRS tokens from a user's stake to their own address
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        
        vm.startPrank(address(newsEvaluation));
        trustToken.stakeTRS(address(this), 10);
        trustToken.transferFromStakeToAdmin(address(this), 10);
        vm.stopPrank();

        assertEq(trustToken.balanceOf(address(this)), trustToken.INITIAL_TRS() - 10);
        assertEq(trustToken.s_staked(address(this)), 0);
    }

    function testUnstakeTRS() external {
        // Test that an admin can unstake TRS tokens for a user
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        vm.startPrank(address(newsEvaluation));
        trustToken.stakeTRS(address(this), 10);
        trustToken.unstakeTRS(address(this), 5);
        vm.stopPrank();
        assertEq(trustToken.s_staked(address(this)), 5);
    }

    function testAddToBlacklist() external {
        // Test that an admin can add a user to the blacklist
        vm.prank(address(newsEvaluation));
        trustToken.addToBlacklist(address(this));
        assertEq(trustToken.s_blacklist(address(this)), true);
    }

    function testAddAdmin() external {
        // Test that an admin can add another admin
        vm.prank(address(newsEvaluation));
        trustToken.addAdmin(msg.sender);
        assertEq(trustToken.s_admins(msg.sender), true);
    }

    function testRemoveAdmin() external {
        // Test that an admin can remove another admin
        vm.startPrank(address(newsEvaluation));
        trustToken.addAdmin(msg.sender);
        trustToken.removeAdmin(msg.sender);
        vm.stopPrank();
        assertEq(trustToken.s_admins(msg.sender), false);
    }

    function testSetTrustLevel() external {
        // Test that an admin can set the trust level for a user
        vm.prank(address(newsEvaluation));
        trustToken.setTrustLevel(address(this), 75);
        assertEq(trustToken.s_trustLevel(address(this)), 75);
    }

    function testSendTokens() external {
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        uint256 initialBalance = trustToken.balanceOf(address(this));
        uint256 amountToSend = 100;
        address recipient = makeAddr("user6");
        
        // Approve the transfer
        trustToken.approve(recipient, amountToSend);
        
        // Send tokens
        vm.prank(recipient);
        trustToken.transferFrom(address(this), recipient, amountToSend);
        
        // Check balances
        uint256 newBalance = trustToken.balanceOf(address(this));
        uint256 recipientBalance = trustToken.balanceOf(recipient);
        
        // Assert balances
        assertEq(newBalance, initialBalance - amountToSend, "Incorrect sender balance");
        assertEq(recipientBalance, amountToSend, "Incorrect recipient balance");
    }

    function testOneTrustedUsers() external {
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        assertEq(trustToken.s_trustedUsers(), 1);
    }

    function testAddTrustedUsers() external {
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        trustToken.transfer(USERS[0], trustToken.TRS_FOR_SHARING());
        assertEq(trustToken.s_trustedUsers(), 2);
    }

    function testRemoveAndAddTrustedUsers() external {
        trustToken.buyBadge{value: trustToken.getBadgePrice()}();
        trustToken.transfer(USERS[0], trustToken.INITIAL_TRS());
        assertEq(trustToken.s_trustedUsers(), 1);
    }

    function testCannotTransferMoreThanStakedTRS() external {
    trustToken.buyBadge{value: trustToken.getBadgePrice()}();
    uint initialTRS = trustToken.INITIAL_TRS();

    vm.startPrank(address(newsEvaluation));
    trustToken.stakeTRS(address(this), initialTRS);
    vm.stopPrank();
    
    // Attempt to transfer more than staked TRS
    vm.expectRevert();
    trustToken.transfer(USERS[0], initialTRS + 1);
    
    // Verify that the transfer did not occur
    assertEq(trustToken.balanceOf(address(this)), initialTRS);
    assertEq(trustToken.balanceOf(USERS[0]), 0);
}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
