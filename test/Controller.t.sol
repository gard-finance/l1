// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/core/Pool.sol";
import "../src/core/Controller.sol";

address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant USDCVAULT = 0x2Af5feB31803BF806b6516EED4b10aC6767cb125;
address constant STARKNET = 0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
address constant STARKGATE = 0xF6080D9fbEEbcd44D89aFfBFd42F098cbFf92816;
uint256 constant L2POOL = 0x010bf70441983bdbf18545f28c43849b5ebc877fa6681de9da4b01b0882239a9;

contract ControllerTest is Test {
    Pool pool;
    Controller controller;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("RPC_1"));
        vm.selectFork(fork);
        pool = new Pool(
            "USD Coin Gard Finance Liquidity Provider Token",
            "GALP-USDC",
            USDCVAULT,
            USDC
        );
        controller = new Controller(address(pool), STARKGATE, STARKNET);
        controller.setL2Pool(L2POOL);
    }

    function testDeposit() public returns (uint256 sharePriceInU) {
        deal(USDC, address(controller), 50_000 ether);
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
