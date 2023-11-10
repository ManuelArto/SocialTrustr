// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/libraries/DataTypes.sol";
import {Script, console} from "forge-std/Script.sol";
import {TrustToken} from "../src/TrustToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract TrustTokenInteractions is Script {
    function buyBadge() external startBroadcast {
        TrustToken trs = getTrustTokenContract();
        uint previousETH = msg.sender.balance;
        uint previousTRS = trs.balanceOf(msg.sender);
        uint fundTRS = trs.getFundsTRS();
        uint contractBalance = address(trs).balance;
        
        console.log("Badge price (wei): %s", trs.getBadgePrice());
        trs.buyBadge{value: trs.getBadgePrice()}();
        logInfos(trs, previousETH, previousTRS, fundTRS, contractBalance);
    }

    function buyFromFunds(uint amount) external startBroadcast {
        TrustToken trs = getTrustTokenContract();
        uint previousETH = msg.sender.balance;
        uint previousTRS = trs.balanceOf(msg.sender);
        uint fundTRS = trs.getFundsTRS();
        uint contractBalance = address(trs).balance;

        console.log("Amount (TRS): %s", amount);
        console.log("Amount (wei): %s", trs.convertTRStoETH(amount));
        trs.buyFromFunds{value: trs.convertTRStoETH(amount)}();
        logInfos(trs, previousETH, previousTRS, fundTRS, contractBalance);
    }

    function sellTrustToken(uint amount) external startBroadcast {
        TrustToken trs = getTrustTokenContract();
        uint previousETH = msg.sender.balance;
        uint previousTRS = trs.balanceOf(msg.sender);
        uint fundTRS = trs.getFundsTRS();
        uint contractBalance = address(trs).balance;

        trs.transfer(address(trs), amount);
        logInfos(trs, previousETH, previousTRS, fundTRS, contractBalance);
    }

    function getBalances() external {
        getBalances(msg.sender);
    }

    function getBalances(address _address) public startBroadcast {
        TrustToken trs = getTrustTokenContract();
        console.log("Address TRS: %s", trs.balanceOf(_address));
        console.log("Address ETH: %s", _address.balance);
        console.log("Contract ETH: %s", address(trs).balance);
        console.log("Contract TRS: %s", trs.getFundsTRS());
    }

    function logInfos(TrustToken trs, uint previousETH, uint previousTRS, uint fundTRS, uint contractBalance) internal view {
        console.log("----------------------------------------------------");
        console.log("My ETH: %s => %s", previousETH, msg.sender.balance);
        console.log("My TRS: %s => %s", previousTRS, trs.balanceOf(msg.sender));
        console.log("----------------------------------------------------");
        console.log("Contract ETH: %s => %s", contractBalance, address(trs).balance);
        console.log("Contract TRS: %s => %s", fundTRS, trs.getFundsTRS());
    }

    function getTrustTokenContract() internal returns (TrustToken) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "TrustToken",
            block.chainid
        );
        return TrustToken(payable(mostRecentlyDeployed));
    }

    modifier startBroadcast {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
