// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IStarknetMessaging.sol";
import "./Pool.sol";
import "./Oracle.sol";
import "./Bridge.sol";

uint256 constant RETURN_WAVE_SELECTOR = 0x6848b3168703261b1a179e607f7202629317349e1e555b3551a9983769551f;

enum Operation {
    Deposit,
    Withdraw
}

contract WrappedController is Ownable {
    using Math for uint256;

    uint256 public L2Pool;
    address public immutable L1Pool;
    address public immutable L1Bridge;
    address public immutable starknet;
    address public immutable oracle;

    constructor(
        address _l1Pool,
        address _l1Bridge,
        address _starknet,
        address _oracle
    ) {
        L1Pool = _l1Pool;
        L1Bridge = _l1Bridge;
        starknet = _starknet;
        oracle = _oracle;
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
    ) external payable onlyOwner returns (uint256 sharePriceInU) {
        uint256 feeTokens = Oracle(oracle).gasInTokens(
            gasleft() * tx.gasprice,
            Pool(L1Pool).asset()
        );
        IStarknet(starknet).consumeMessageFromL2(L2Pool, payload);
        uint256 amount = payload[1] | (payload[2] << 128);
        if (uint8(payload[0]) == uint8(Operation.Deposit)) {
            amount = amount - feeTokens;
            IERC20(Pool(L1Pool).asset()).approve(address(L1Pool), amount);
            uint256 shares = Pool(L1Pool).deposit(amount, address(this), minLP);
            sharePriceInU = amount.mulDiv(1e18, shares);
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
            uint256 assets = Pool(L1Pool).redeem(amount, address(this)) -
                feeTokens;
            sharePriceInU = assets.mulDiv(1e18, amount);
            IERC20(Pool(L1Pool).asset()).approve(address(L1Bridge), assets);
            Bridge(L1Bridge).bridgeToL2{value: bridgeFee}(assets, L2Pool);
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
        }
        IERC20(Pool(L1Pool).asset()).transfer(msg.sender, feeTokens);
    }
}
