// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    /**
     * @dev Get the price of the asset from the Chainlink price feed.
     * @param priceFeed The Chainlink price feed contract.
     * @return The latest price of the asset with 18 decimals
     */
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // https://docs.chain.link/data-feeds/price-feeds/addresses
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit (8 + 10)
        return uint256(answer * 1e10);
    }

    /**
     * @dev Convert an amount of ETH to USD.
     * @param ethAmount The amount of ETH in wei to be converted.
     * @param priceFeed The Chainlink price feed contract.
     * @return The equivalent amount in USD.
     */
    function convertETHtoUSD(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd / 1e18;
    }

    /**
     * @dev Convert an amount of USD to ETH.
     * @param usdAmount The amount of USD to be converted.
     * @param priceFeed The Chainlink price feed contract.
     * @return The equivalent amount in ETH (wei).
     */
    function convertUSDtoETH(
        uint256 usdAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 usdAmountInEth = (usdAmount * 1e18) / ethPrice;

        return usdAmountInEth * 1e18;
    }
}