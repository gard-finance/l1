// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IBridge is IERC4626 {
    function L2Token() external view returns (uint256 token);

    function bridgeToL2(uint256 amount, uint256 receiver) external;

    function bridgeFromL2(uint256 amount, address receiver) external;
}
