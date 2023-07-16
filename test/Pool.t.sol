// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/core/Pool.sol";

address constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
address constant CRVUSDVAULT = 0x6282FCa35943faBE45d6056F3751b3cf2Bf4504E;

contract PoolTest is Test {
    Pool pool;

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
        uint shares = pool.deposit(25_000 ether, address(this));
        pool.mint(pool.convertToShares(25_000), address(this));
        pool.withdraw(
            pool.convertToAssets(shares / 2),
            address(this),
            address(this)
        );
        pool.redeem(shares / 2, address(this), address(this));
    }
}
