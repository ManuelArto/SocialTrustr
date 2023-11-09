// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/Errors.sol";

contract TrustToken is ERC20 {
    mapping(address => bool) public s_admins;
    mapping(address => bool) public s_blacklist;

    uint public constant INITIAL_TRS = 500;
    uint public constant TRS_FOR_EVALUATION = 100;
    uint public constant TRS_FOR_SHARING = 200;
    // * 50TRS = 1ETH
    uint public constant TRS_FOR_ETH = 50 * 1; // TODO: convert to EUR using Stablecoin or FiatContract

    modifier onlyAdmins() {
        if (!s_admins[msg.sender]) {
            revert Errors.TrustToken_OnlyAdmins();
        }
        _;
    }

    constructor() ERC20("TrustToken", "TRS") {
        s_admins[msg.sender] = true;
    }

    /**
     * @dev Buy a badge by sending ETH and receiving initial TRS tokens.
     */
    function buyBadge() external payable {
        if (balanceOf(msg.sender) != 0) {
            revert Errors.TrustToken_UserAlreadyHasBadge();
        }
        if (s_blacklist[msg.sender]) {
            revert Errors.TrustToken_UserIsBlacklisted();
        }
        if (convertETHtoTRS(msg.value) < INITIAL_TRS) {
            revert Errors.TrustToken_NotEnoughETH(INITIAL_TRS / TRS_FOR_ETH);
        }

        uint toMint = INITIAL_TRS;
        if (getFundsTRS() > 0 && getFundsTRS() < INITIAL_TRS) {
            toMint = INITIAL_TRS - getFundsTRS();
            transfer(msg.sender, getFundsTRS());
        } else if (getFundsTRS() >= INITIAL_TRS) {
            toMint = 0;
            transfer(msg.sender, INITIAL_TRS);
        }

        console.log(toMint);

        if (toMint > 0) {
            _mint(msg.sender, INITIAL_TRS);
        }

        uint excess = msg.value - convertTRStoETH(INITIAL_TRS);
        if (excess > 0) {
            sendETH(msg.sender, excess);
        }
    }

    /**
     * @dev Buy TrustToken directly from contract funds by sending ETH, only if the user has badge.
     */
    function buyTrustTokenFromFunds() external payable {
        if (balanceOf(msg.sender) == 0) {
            revert Errors.TrustToken_UserHasNoBadge();
        }

        uint trsAmount = convertETHtoTRS(msg.value);
        if (trsAmount > getFundsTRS()) {
            revert Errors.TrustToken_NotEnoughTRS(getFundsTRS());
        }

        transfer(msg.sender, trsAmount);
    }

    /**
     * @dev Stake TRS tokens to a contract address. Given back or tuned after News Validation.
     * @param user The address of the user staking TRS tokens.
     * @param contractAddress The address of the contract to stake to.
     * @param amount The amount of TRS tokens to stake.
     */
    function stakeTRS(address user, address contractAddress, uint amount) external onlyAdmins {
        _transfer(user, contractAddress, amount);
    }

    function addToBlacklist(address user) external onlyAdmins {
        s_blacklist[user] = true;
    }

    function addAdmin(address admin) external onlyAdmins {
        s_admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyAdmins {
        s_admins[admin] = false;
    }

    /**
     * @dev Get the TRS balance of the contract.
     */
    function getFundsTRS() public view returns (uint) {
        return balanceOf(address(this));
    }

    /**
     * @dev Get the price of a badge.
     */
    function getBadgePrice() public pure returns (uint) {
        return INITIAL_TRS / TRS_FOR_ETH;
    }

    /* INTERNAL FUNCTIONS */

    /**
     * @dev Convert ETH value to TRS tokens.
     * @param amount The amount of WEI to convert.
     * @return The equivalent amount of TRS tokens.
     */
    function convertETHtoTRS(uint amount) internal pure returns (uint) {
        return amount * (10 ** 18) * TRS_FOR_ETH;
    }

    /**
     * @dev Convert TRS tokens to ETH.
     * @param amount The amount of TRS to convert.
     * @return The equivalent amount of WEI.
     */
    function convertTRStoETH(uint amount) internal pure returns (uint) {
        return amount / (10 ** 18) / TRS_FOR_ETH;
    }

    /**
     * @dev Send ETH to the specified address.
     * @param to The address to send ETH to.
     * @param amount The amount of ETH to send.
     */
    function sendETH(address to, uint amount) internal {
        (bool callSuccess, ) = payable(to).call{value: amount}("");
        require(callSuccess, "TrustToken: Failed to send ETH");
    }

    /**
     * @dev Override the _update function to send ETH back to the user in exchange for TRS.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._update(from, to, amount);
        if (to == address(this)) {
            uint ethToSend = amount / TRS_FOR_ETH;
            sendETH(from, ethToSend);
        }
    }
}
