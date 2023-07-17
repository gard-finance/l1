// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

import "../interfaces/IBridge.sol";
import "./Pool.sol";

address constant STARKNET_CORE_GOERLI = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;

interface IStarknet {
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256);

    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);
}

uint256 constant MINT_SELECTOR = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;

/**
 * @title Bridge
 * @author Flydexo - @Flydexo
 * @notice We make the bridge ourselves with L1-L2 messaging and a wrapped ERC20 equivalent on Starknet.
 */
contract Bridge is IBridge {
    uint256 public L2Token;
    address public immutable asset;

    constructor(address _asset) {
        asset = _asset;
    }

    function setL2Token(uint256 token) external {
        require(L2Token == 0);
        L2Token = token;
    }

    function bridgeToL2(
        uint256 amount,
        uint256[] calldata data // [recipient, amount.low, amount.high]
    ) external payable override {
        assert(data[1] | (data[2] << 128) == amount);
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IStarknet(STARKNET_CORE_GOERLI).sendMessageToL2{value: msg.value}(
            L2Token,
            MINT_SELECTOR,
            data
        );
    }

    function bridgeFromL2(uint256[] calldata payload) external override {
        IStarknet(STARKNET_CORE_GOERLI).consumeMessageFromL2(L2Token, payload);
        address receiver = address(uint160(payload[0]));
        uint256 amount = payload[1] | (payload[2] << 128);
        IERC20(asset).transfer(receiver, amount);
    }
}
