// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "./IUSDT.sol";
import "../../FlashJoin.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/token/TransferHelper.sol";

contract TetherJoin is FlashJoin {
    using TransferHelper for IERC20;

    constructor(address asset_) FlashJoin(asset_) {}

    /// @dev Calculate the amount of `asset` that needs to be sent to receive `amount` of USDT.
    function _reverseFee(uint256 amount) internal view returns (uint256) {
        return amount * 1000000 / (1000000 - (IUSDT(asset).basisPointsRate() * 100));
    }

    /// @dev Take `amount` `asset` from `user` using `transferFrom`, minus any unaccounted `asset` in this contract.
    function _join(address user, uint128 amount) internal override returns (uint128) {
        IERC20 token = IERC20(asset);
        uint256 _storedBalance = storedBalance;
        uint256 available = token.balanceOf(address(this)) - _storedBalance; // Fine to panic if this underflows
        unchecked {
            if (available == 0) {
                token.safeTransferFrom(user, address(this), amount);
                amount = uint128(token.balanceOf(address(this)) - _storedBalance);
            } else if (available < amount) {
                token.safeTransferFrom(user, address(this), _reverseFee(amount - available));
                amount = uint128(token.balanceOf(address(this)) - _storedBalance);
            }
            storedBalance = _storedBalance + amount; // Unlikely that a uint128 added to the stored balance will make it overflow
        }
        return amount;
    }
}