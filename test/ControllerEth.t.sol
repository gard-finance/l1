// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/core/Pool.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../src/core/EthController.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant WETHVAULT = 0x865500c065287B6727d31ddD9BAc8e959bBB809F;
address constant STARKNET = 0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
address constant STARKGATE = 0xae0Ee0A63A2cE6BaeEFFE56e7714FB4EFE48D419;
uint256 constant L2POOL = 0x010bf70441983bdbf18545f28c43849b5ebc877fa6681de9da4b01b0882239a9;

contract ControllerEthTest is Test {
    using Math for uint256;
    Pool pool;
    EthController controller;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("RPC_1"));
        vm.selectFork(fork);
        pool = new Pool(
            "USD Coin Gard Finance Liquidity Provider Token",
            "GALP-USDC",
            WETHVAULT,
            WETH
        );
        controller = new EthController(address(pool), STARKGATE, STARKNET);
        controller.setL2Pool(L2POOL);
    }

    function testDeposit() public returns (uint256 sharePriceInU) {
        deal(WETH, address(controller), 50_000 ether);
        uint256[] memory data = new uint256[](3);
        data[0] = uint256(Operation.Deposit);
        data[1] = 2e18;
        data[2] = 0;
        sharePriceInU = controller.consumeL2Message{value: 2}(data, 1, 1, 0);
    }

    function testWithdraw() public {
        uint256 sharePriceInU = testDeposit();
        uint256[] memory data = new uint256[](3);
        data[0] = uint256(Operation.Withdraw);
        data[1] = pool.balanceOf(address(controller));
        data[2] = 0;
        sharePriceInU = controller.consumeL2Message{value: 2}(data, 1, 1, 0);
    }
}
