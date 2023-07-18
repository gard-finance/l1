// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/mock/Vault.sol";
import "../src/core/Bridge.sol";
import "../src/core/Pool.sol";
import "../src/core/WrappedController.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MockVault vault = new MockVault();
        Bridge bridge = new Bridge(
            MockPool(vault.want()).asset(),
            0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        );
        Pool pool = new Pool(
            "GALP",
            "GALP",
            address(vault),
            MockPool(vault.want()).asset()
        );
        Oracle oracle = new Oracle();
        WrappedController controller = new WrappedController(
            address(pool),
            address(bridge),
            0xde29d060D45901Fb19ED6C6e959EB22d8626708e,
            address(oracle)
        );
        vm.stopBroadcast();
        console.log("vault", address(vault));
        console.log("bridge", address(bridge));
        console.log("pool", address(pool));
        console.log("controller", address(controller));
    }
}
