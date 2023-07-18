// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

interface ChainlinkOracle {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

address constant ETH_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract Oracle {
    using Math for uint256;

    function gasInTokens(
        uint256 ethAmount,
        address token
    ) external view returns (uint256 tokens) {
        if (token == WETH) return ethAmount;
        (, int256 _ethPrice, , , ) = ChainlinkOracle(ETH_FEED)
            .latestRoundData();
        uint256 ethPrice = uint256(_ethPrice) *
            10 ** (18 - ChainlinkOracle(ETH_FEED).decimals());
        return ethPrice.mulDiv(ethAmount, 1e18);
    }
}
