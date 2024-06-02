// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Ownable} from 'oz/access/Ownable.sol';
import {IInsurancePool} from 'interfaces/IInsurancePool.sol';
import {ERC4626, IERC20, ERC20} from 'oz/token/ERC20/extensions/ERC4626.sol';

contract InsurancePool is IInsurancePool, ERC4626, Ownable {
  uint256 public totalLocked;

  mapping(uint256 insuranceId => uint256 locked) public amountLocked;

  constructor(
    IERC20 _token,
    string memory _name,
    string memory _symbol,
    address _owner
  ) ERC4626(_token) ERC20(_name, _symbol) Ownable(_owner) {}

  function _withdraw(
    address caller,
    address receiver,
    address _owner,
    uint256 assets,
    uint256 shares
  ) internal override {
    uint256 _available = totalAssets() - totalLocked;
    if (_available < assets) revert InsufficientFunds();

    super._withdraw(caller, receiver, _owner, assets, shares);
  }

  function lock(uint256 _insuranceId, uint256 _amount) external override onlyOwner {
    if (amountLocked[_insuranceId] > 0) revert InsuranceAlreadyLocked();

    uint256 _available = totalAssets() - totalLocked;
    if (_available < _amount) revert InsufficientFunds();

    amountLocked[_insuranceId] += _amount;
    totalLocked += _amount;

    emit Locked(_insuranceId, _amount);
  }

  function unlock(uint256 _insuranceId) external override onlyOwner {
    uint256 _amount = amountLocked[_insuranceId];

    if (_amount == 0) revert InsuranceNotLocked();

    amountLocked[_insuranceId] -= _amount;
    totalLocked -= _amount;

    emit Unlocked(_insuranceId, _amount);
  }

  function execute(uint256 _insuranceId, uint256 _amount) external override onlyOwner {
    uint256 _locked = amountLocked[_insuranceId];

    if (_locked == 0) revert InsuranceNotLocked();
    if (_locked < _amount) revert InsufficientFunds();

    amountLocked[_insuranceId] -= _amount;
    totalLocked -= _amount;

    IERC20(asset()).transfer(owner(), _amount);

    emit Executed(_insuranceId, _amount);
  }
}
