// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/core/Pool.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../src/core/WrappedController.sol";
import "../src/core/Bridge.sol";

address constant CRVUSD = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant CRVUSDVAULT = 0x865500c065287B6727d31ddD9BAc8e959bBB809F;
address constant STARKNET = 0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
uint256 constant L2CRVUSD = 0x010bf70441983bdbf18545f28c43849b5ebc877fa6681de9da4b01b0882239a9;
uint256 constant L2POOL = 0x010bf70441983bdbf18545f28c43849b5ebc877fa6681de9da4b01b0882239a9;

contract ControllerEthTest is Test {
    using Math for uint256;
    Pool pool;
    WrappedController controller;
    Bridge bridge;

    function setUp() public {
        uint256 fork = vm.createFork(vm.envString("RPC_1"));
        vm.selectFork(fork);
        pool = new Pool(
            "Curve USD Gard Finance Liquidity Provider Token",
            "GALP-crvUSD",
            CRVUSDVAULT,
            CRVUSD
        );
        bridge = new Bridge(CRVUSD, STARKNET);
        bridge.setL2Token(L2CRVUSD);
        Oracle oracle = new Oracle();
        controller = new WrappedController(
            address(pool),
            address(bridge),
            STARKNET,
            address(oracle)
        );
        controller.setL2Pool(L2POOL);
    }

    function testDeposit() public returns (uint256 sharePriceInU) {
        deal(CRVUSD, address(controller), 50_000 ether);
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
