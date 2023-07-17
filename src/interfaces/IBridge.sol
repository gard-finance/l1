// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

interface IBridge {
    function L2Token() external view returns (uint256 token);

    function bridgeToL2(
        uint256 amount,
        uint256[] calldata data
    ) external payable;

    function bridgeFromL2(uint256[] calldata payload) external;
}
