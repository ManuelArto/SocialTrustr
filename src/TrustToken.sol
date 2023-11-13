// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./libraries/services/PriceConverter.sol";
import "./libraries/types/Errors.sol";

contract TrustToken is ERC20 {
    using PriceConverter for uint256;
    
    AggregatorV3Interface private s_priceFeed;
    mapping(address => uint) public s_trustLevel; // Range [0, 100]
    mapping(address => bool) public s_admins;
    mapping(address => bool) public s_blacklist;
    
    uint public trustedUsers = 0;

    // 500 TRS = 50 USD
    uint public constant INITIAL_USD_PRICE = 50;
    uint public constant INITIAL_TRS = 500;
    uint public constant TRS_FOR_USD = (INITIAL_TRS * 1e18) / INITIAL_USD_PRICE;
    uint public constant USD_FOR_TRS = (INITIAL_USD_PRICE * 1e18) / INITIAL_TRS;
    uint public constant TRS_FOR_EVALUATION = 100;
    uint public constant TRS_FOR_SHARING = 200;

    modifier onlyAdmins() {
        if (!s_admins[msg.sender]) {
            revert Errors.TrustToken_OnlyAdmins();
        }
        _;
    }

    constructor(address priceFeed) ERC20("TrustToken", "TRS") {
        s_admins[msg.sender] = true;
        s_priceFeed = AggregatorV3Interface(priceFeed);
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

        if (msg.value.convertETHtoUSD(s_priceFeed) < INITIAL_USD_PRICE) {
            revert Errors.TrustToken_NotEnoughETH(INITIAL_USD_PRICE.convertUSDtoETH(s_priceFeed));
        }

        uint toMint = INITIAL_TRS;
        if (getFundsTRS() > 0 && getFundsTRS() < INITIAL_TRS) {
            toMint = INITIAL_TRS - getFundsTRS();
            _transfer(address(this), msg.sender, getFundsTRS());
        } else if (getFundsTRS() >= INITIAL_TRS) {
            toMint = 0;
            _transfer(address(this), msg.sender, INITIAL_TRS);
        }

        if (toMint > 0) {
            _mint(msg.sender, toMint);
        }

        uint excess = msg.value - convertTRStoETH(INITIAL_TRS);
        if (excess > 0) {
            sendETH(msg.sender, excess);
        }

        s_trustLevel[msg.sender] = 50;
        trustedUsers++;
    }

    /**
     * @dev Buy TrustToken directly from contract funds by sending ETH, only if the user has badge.
     */
    function buyFromFunds() external payable {
        if (balanceOf(msg.sender) == 0) {
            revert Errors.TrustToken_UserHasNoBadge();
        }

        uint trsAmount = convertETHtoTRS(msg.value);
        if (trsAmount > getFundsTRS()) {
            revert Errors.TrustToken_NotEnoughTRS(getFundsTRS());
        }

        _transfer(address(this), msg.sender, trsAmount);
    }

    /* ONLY FOR ADMINS */ 

    /**
     * @dev Stake TRS tokens to a contract address. Given back or tuned after News Validation. Only for admins.
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

    function setTrustLevel(address user, uint trustLevel) external onlyAdmins {
        s_trustLevel[user] = trustLevel;
    }


    /**
     * @dev Get the TRS balance of the contract.
     */
    function getFundsTRS() public view returns (uint) {
        return balanceOf(address(this));
    }

    /**
     * @dev Get the price of a badge in wei.
     */
    function getBadgePrice() public view returns (uint) {
        return convertTRStoETH(INITIAL_TRS);
    }

    /**
     * @dev Convert ETH value to TRS tokens.
     * @param amount The amount of WEI to convert.
     * @return The equivalent amount of TRS tokens.
     */
    function convertETHtoTRS(uint amount) public view returns (uint) {
        return (amount.convertETHtoUSD(s_priceFeed) * TRS_FOR_USD) / 1e18;
    }

    /**
     * @dev Convert TRS tokens to ETH.
     * @param amount The amount of TRS to convert.
     * @return The equivalent amount of WEI.
     */
    function convertTRStoETH(uint amount) public view returns (uint) {
        return (amount * USD_FOR_TRS).convertUSDtoETH(s_priceFeed) / 1e18;
    }

    function getTrustLevel(address user) public view returns (uint) {
        return s_trustLevel[user];
    }

    /* INTERNAL FUNCTIONS */

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
            uint ethToSend = convertTRStoETH(amount);
            sendETH(from, ethToSend);
            if (balanceOf(from) == 0) {
                trustedUsers--;
            }
        }
    }
}
