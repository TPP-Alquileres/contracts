// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Ownable} from 'oz/access/Ownable.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';

contract RentInsurance is IRentInsurance, Ownable {
  mapping(bytes32 insuranceId => InsuranceData data) public insurances;

  function initializeInsurance(address _owner, address _tenant, uint256 _amount, uint256 _duration) external {
    if (_owner == address(0) || _tenant == address(0)) revert InvalidAddress();
    if (_owner == _tenant) revert InvalidAddress();
    if (_amount == 0) revert InvalidAmount();
    if (_duration == 0) revert InvalidDuration();

    bytes32 _insuranceId = keccak256(abi.encodePacked(_owner, _tenant, _amount, _duration));

    if (insurances[_insuranceId].owner != address(0)) revert InsuranceAlreadyExists();

    insurances[_insuranceId] = InsuranceData({owner: _owner, tenant: _tenant, amount: _amount, duration: _duration});

    emit InsuranceInitialized(_insuranceId, _owner, _tenant, _amount, _duration);
  }
}
