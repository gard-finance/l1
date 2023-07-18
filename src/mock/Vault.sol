// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Pool.sol";

contract MockVault is ERC20 {
    address public immutable want;

    constructor() ERC20("LPToken", "LP") {
        want = address(new MockPool());
    }

    function getPricePerFullShare() external pure returns (uint256) {
        return 1;
    }

    function deposit(uint256 amount) external {
        ERC20(want).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        ERC20(want).transfer(msg.sender, amount);
    }
}
