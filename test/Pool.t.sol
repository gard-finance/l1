// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/core/Pool.sol";
import "../src/core/Bridge.sol";

address constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
address constant CRVUSDVAULT = 0x6282FCa35943faBE45d6056F3751b3cf2Bf4504E;

contract PoolTest is Test {
    Pool pool;
    uint256[] data;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("RPC_1"));
        vm.selectFork(fork);
        pool = new Pool(
            "crvUSD Gard Finance Liquidity Provider Token",
            "GALP-crvUSD",
            CRVUSDVAULT,
            CRVUSD
        );
    }

    function testDepositAndWithdraw() public {
        deal(CRVUSD, address(this), 50_000 ether);
        IERC20(CRVUSD).approve(address(pool), 25_000 ether);
        uint shares = pool.deposit(50_000 ether, address(this));
        pool.withdraw(
            pool.convertToAssets(shares / 2),
            address(this),
            address(this)
        );
        pool.redeem(shares / 2, address(this), address(this));
    }

    function testLOL() public {
        vm.createSelectFork(
            "https://eth-goerli.g.alchemy.com/v2/0qCzIAfBHKYu9awUKRGsw9BRzIvBTs_b"
        );
        deal(
            0x2E8D98fd126a32362F2Bd8aA427E59a1ec63F780,
            address(this),
            500 ether
        );
        IERC20(0x2E8D98fd126a32362F2Bd8aA427E59a1ec63F780).approve(
            0x6f25C6e6E1deE26bE07F39e91693718C9AfFd8B6,
            500 ether
        );
        data.push(
            0x013dd3eE4C46a5F38683767eAABBbFB0f152A2399Dc205D684ef41b35BE621bC
        );
        data.push(500 ether);
        data.push(0);
        console.log(500 ether);
        console.log(data[0], data[1], data[2]);
        Bridge(0x6f25C6e6E1deE26bE07F39e91693718C9AfFd8B6).bridgeToL2{
            value: 0.0001 ether
        }(500 ether, data);
    }
}
