// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint() external {
        _mint(msg.sender, 100 ether);
    }
}

contract MockPool is ERC20 {
    address public immutable asset;
    uint256 public exchangeRate = 1;

    constructor() ERC20("LPToken", "LP") {
        asset = address(new MintableToken("Curve USD", "crvUSD"));
    }

    function deposit(uint256 amount) external returns (uint256) {
        ERC20(asset).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function withdraw(uint256 amount) external returns (uint256) {
        _burn(msg.sender, amount);
        ERC20(asset).transfer(msg.sender, amount);
        return amount;
    }

    function minter() external view returns (address) {
        return address(this);
    }
}
