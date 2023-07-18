// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

import "../interfaces/IBridge.sol";
import "./Pool.sol";
import "../interfaces/IStarknetMessaging.sol";

uint256 constant MINT_SELECTOR = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;

/**
 * @title Bridge
 * @author Flydexo - @Flydexo
 * @notice We make the bridge ourselves with L1-L2 messaging and a wrapped ERC20 equivalent on Starknet.
 */
contract Bridge is IBridge {
    uint256 public L2Token;
    address public immutable starknet;
    address public immutable asset;

    constructor(address _asset, address _starknet) {
        asset = _asset;
        starknet = _starknet;
    }

    function setL2Token(uint256 token) external {
        require(L2Token == 0);
        L2Token = token;
    }

    function bridgeToL2(
        uint256 amount,
        uint256 recipient
    ) external payable override {
        uint256[] memory data = new uint256[](3);
        uint256 low = uint256(uint128(amount));
        uint256 high = uint256(uint128(amount >> 128));
        data[0] = recipient;
        data[1] = low;
        data[2] = high;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IStarknet(starknet).sendMessageToL2{value: msg.value}(
            L2Token,
            MINT_SELECTOR,
            data
        );
    }

    function bridgeFromL2(uint256[] calldata payload) external override {
        IStarknet(starknet).consumeMessageFromL2(L2Token, payload);
        address receiver = address(uint160(payload[0]));
        uint256 amount = payload[1] | (payload[2] << 128);
        IERC20(asset).transfer(receiver, amount);
    }
}
