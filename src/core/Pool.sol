// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@beefy/BIFI/interfaces/beefy/IVault.sol";
import "@conic/contracts/LpToken.sol";
import "@conic/contracts/ConicPool.sol";
import "forge-std/console.sol";

uint256 constant UNLIMITED = type(uint256).max - 1;

/**
 * @title Pool
 * @author Flydexo - @Flydexo
 * @notice Pool is a pool that manages a token on Beefy and receives orders from the Starknet core contract on L1.
 */
contract Pool is ERC20 {
    IVault public immutable vault;
    address public immutable asset;
    ConicPool public immutable pool;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vault,
        address _asset
    ) ERC20(_name, _symbol) {
        vault = IVault(_vault);
        asset = _asset;
        pool = ConicPool(payable(LpToken(address(vault.want())).minter()));
    }

    function totalAssets() external view returns (uint256 totalManagedAssets) {
        return convertToAssets(vault.balanceOf(address(this)));
    }

    function convertToShares(
        uint256 assets
    ) public view returns (uint256 shares) {
        uint256 assetPriceinCNCLP = pool.exchangeRate();
        return (assets * assetPriceinCNCLP) / vault.getPricePerFullShare();
    }

    function convertToAssets(
        uint256 shares
    ) public view returns (uint256 assets) {
        uint256 valueMoo = vault.getPricePerFullShare() * shares;
        uint256 assetPriceinCNCLP = pool.exchangeRate();
        return valueMoo / assetPriceinCNCLP;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares) {
        IERC20(asset).transferFrom(msg.sender, address(this), assets);
        IERC20(asset).approve(address(pool), assets);
        uint256 cncLPDeposit = pool.deposit(assets, 0, false);
        IERC20(vault.want()).approve(address(vault), cncLPDeposit);
        uint256 oldBalance = vault.balanceOf(address(this));
        vault.deposit(cncLPDeposit);
        shares = vault.balanceOf(address(this)) - oldBalance;
        _mint(receiver, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares) {
        require(msg.sender == owner);
        shares = convertToShares(assets);
        _burn(owner, shares);
        uint oldCNCBalance = vault.want().balanceOf(address(this));
        vault.withdraw(shares);
        pool.withdraw(
            vault.want().balanceOf(address(this)) - oldCNCBalance,
            assets
        );
        IERC20(asset).transfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        require(msg.sender == owner);
        assets = convertToAssets(shares);
        _burn(owner, shares);
        uint oldCNCBalance = vault.want().balanceOf(address(this));
        vault.withdraw(shares);
        pool.withdraw(
            vault.want().balanceOf(address(this)) - oldCNCBalance,
            assets
        );
        IERC20(asset).transfer(receiver, assets);
    }

    /**
     * INTERNALS
     */

    function _determineMinLPReceived(
        uint256 assetAmount
    ) internal view returns (uint256) {
        return 0;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256 min) {
        if (a < b) {
            min = a;
        } else {
            min = b;
        }
    }
}
