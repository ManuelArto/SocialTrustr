// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

error NewsSharing_NotOwner();

contract NewsSharing {

    address private immutable i_owner;

    modifier is_owner() {
        // require(msg.sender == i_owner, "Only owner can access");
        if (msg.sender != i_owner) { revert NewsSharing_NotOwner(); }
        _;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

}