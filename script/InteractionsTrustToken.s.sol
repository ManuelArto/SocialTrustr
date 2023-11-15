// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {TrustToken} from "../src/TrustToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import "../src/libraries/types/DataTypes.sol";

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

    function transferTrs(address _to, uint amount) public startBroadcast {
        TrustToken trs = getTrustTokenContract();
        if (_to == address(0)) {
            _to = address(trs);
        }

        uint myPrevETH = msg.sender.balance;
        uint myPrevTRS = trs.balanceOf(msg.sender);
        uint toPrevTRS = trs.balanceOf(_to);
        uint toPrevBalance = _to.balance;

        trs.transfer(_to, amount);
        logInfos(trs, myPrevETH, myPrevTRS, toPrevTRS, toPrevBalance, _to);
    }

    function getInfos() external {
        getInfos(msg.sender);
    }

    function sellTrustToken(uint amount) external {
        transferTrs(address(0), amount);
    }

    function getInfos(address _address) public startBroadcast {
        TrustToken trs = getTrustTokenContract();
        console.log("----------------------------------------------------");
        console.log("TRS: %s, Staked:", trs.balanceOf(_address), trs.s_staked(_address));
        console.log("ETH: %s", _address.balance);
        console.log("TrustLevel : %s", trs.getTrustLevel(_address));
        console.log("----------------------------------------------------");
        console.log("Contract ETH: %s", address(trs).balance);
        console.log("Contract TRS: %s", trs.getFundsTRS());
        console.log("----------------------------------------------------");
        console.log("TrustedUsers: %s", trs.s_trustedUsers());
    }

    function logInfos(TrustToken trs, uint previousETH, uint previousTRS, uint fundTRS, uint addressBalance, address _to) internal view {
        console.log("----------------------------------------------------");
        console.log("My ETH: %s => %s", previousETH, msg.sender.balance);
        console.log("My TRS: %s => %s", previousTRS, trs.balanceOf(msg.sender));
        console.log("----------------------------------------------------");
        string memory toText = _to == address(trs) ? "Contract" : "Address";
        console.log("%s ETH: %s => %s", toText, addressBalance, _to.balance);
        console.log("%s TRS: %s => %s", toText, fundTRS, trs.balanceOf(_to));
    }

    function logInfos(TrustToken trs, uint previousETH, uint previousTRS, uint fundTRS, uint addressBalance) internal view {
        logInfos(trs, previousETH, previousTRS, fundTRS, addressBalance, address(trs));
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
