// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Events {
    event NewsCreated(
        uint indexed id,
        address indexed sender,
        string title,
        string ipfsCid,
        string chatName,
        uint parentNews
    );
}
