// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TrustToken is ERC20 {

    constructor() ERC20("TRS", "TrustToken") {}

}
