// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Ownable} from 'oz/access/Ownable.sol';
import {ERC4626, IERC20, ERC20} from 'oz/token/ERC20/extensions/ERC4626.sol';

contract InsurancePool is ERC4626, Ownable {
  uint256 public totalLocked;

  mapping(bytes32 insuranceId => uint256 locked) public amountLocked;

  error InsuranceAlreadyLocked();
  error InsuranceNotLocked();
  error InsufficientFunds();

  event Locked(bytes32 indexed insuranceId, uint256 amount);
  event Unlocked(bytes32 indexed insuranceId, uint256 amount);

  constructor(IERC20 _token, string memory _name, string memory _symbol) ERC4626(_token) ERC20(_name, _symbol) {}

  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    uint256 _available = totalAssets() - totalLocked;
    if (_available < assets) revert InsufficientFunds();

    super._withdraw(caller, receiver, owner, assets, shares);
  }

  function lock(bytes32 _insuranceId, uint256 _amount) external onlyOwner {
    if (amountLocked[_insuranceId] > 0) revert InsuranceAlreadyLocked();

    uint256 _available = totalAssets() - totalLocked;
    if (_available < _amount) revert InsufficientFunds();

    amountLocked[_insuranceId] += _amount;
    totalLocked += _amount;

    emit Locked(_insuranceId, _amount);
  }

  function unlock(bytes32 _insuranceId) external onlyOwner {
    uint256 _amount = amountLocked[_insuranceId];

    if (_amount == 0) revert InsuranceNotLocked();

    amountLocked[_insuranceId] -= _amount;
    totalLocked -= _amount;

    emit Unlocked(_insuranceId, _amount);
  }
}
