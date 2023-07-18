// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStarknetMessaging.sol";
import "./Pool.sol";
import "./Bridge.sol";

uint256 constant RETURN_WAVE_SELECTOR = 0;

enum Operation {
    Deposit,
    Withdraw
}

contract WrappedController is Ownable {
    uint256 public L2Pool;
    address public immutable L1Pool;
    address public immutable L1Bridge;
    address public immutable starknet;

    constructor(address _l1Pool, address _l1Bridge, address _starknet) {
        L1Pool = _l1Pool;
        L1Bridge = _l1Bridge;
        starknet = _starknet;
    }

    function setL2Pool(uint256 _pool) external onlyOwner {
        L2Pool = _pool;
    }

    /**
     *
     * @param payload [Operation, amount.low, amount.high]
     */
    function consumeL2Message(
        uint256[] calldata payload,
        uint256 bridgeFee,
        uint256 waveFee,
        uint256 minLP
    ) external onlyOwner {
        IStarknet(starknet).consumeMessageFromL2(L2Pool, payload);
        uint256 amount = payload[1] | (payload[2] << 128);
        if (uint8(payload[0]) == uint8(Operation.Deposit)) {
            IERC20(Pool(L1Pool).asset()).approve(address(L1Pool), amount);
            uint256 shares = Pool(L1Pool).deposit(amount, address(this), minLP);
            uint sharePriceInU = (amount * 1e18) / shares;
            uint256[] memory wavePayload = new uint256[](3);
            uint256 low = uint256(uint128(sharePriceInU));
            uint256 high = uint256(uint128(sharePriceInU >> 128));
            wavePayload[0] = low;
            wavePayload[1] = high;
            IStarknet(starknet).sendMessageToL2{value: waveFee}(
                L2Pool,
                RETURN_WAVE_SELECTOR,
                wavePayload
            );
        } else {
            Pool(L1Pool).vault().approve(address(L1Pool), amount);
            uint256 assets = Pool(L1Pool).redeem(amount, address(this));
            uint sharePriceInU = (assets * 1e18) / amount;
            IERC20(Pool(L1Pool).asset()).approve(address(L1Bridge), assets);
            uint256[] memory bridgePayload = new uint256[](3);
            uint256 low = uint256(uint128(assets));
            uint256 high = uint256(uint128(assets >> 128));
            bridgePayload[0] = L2Pool;
            bridgePayload[1] = low;
            bridgePayload[2] = high;
            Bridge(L1Bridge).bridgeToL2{value: bridgeFee}(
                assets,
                bridgePayload
            );
            uint256[] memory wavePayload = new uint256[](3);
            low = uint256(uint128(sharePriceInU));
            high = uint256(uint128(sharePriceInU >> 128));
            wavePayload[0] = low;
            wavePayload[1] = high;
            IStarknet(starknet).sendMessageToL2{value: waveFee}(
                L2Pool,
                RETURN_WAVE_SELECTOR,
                wavePayload
            );
        }
    }
}
