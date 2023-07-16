// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

import "../interfaces/IBridge.sol";

/**
 * @title WrappedPool
 * @author Flydexo - @Flydexo
 * @notice WrappedPool is a pool managing a token which isn't bridgeable through Starknet bridges. We make the bridge ourselves with L1-L2 messaging and a wrapped ERC20 equivalent on Starknet.
 */
abstract contract WrappedPool is IBridge {

}
