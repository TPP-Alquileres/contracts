// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Ownable} from 'oz/access/Ownable.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

contract RentInsurance is IRentInsurance, Ownable {
  mapping(bytes32 insuranceId => InsuranceData data) public insurances;

  function initializeInsurance(address _tenant, uint256 _amount, uint256 _duration) external override {
    if (_tenant == address(0)) revert InvalidAddress();
    if (msg.sender == _tenant) revert InvalidAddress();
    if (_amount == 0) revert InvalidAmount();
    if (_duration == 0) revert InvalidDuration();

    bytes32 _insuranceId = keccak256(abi.encodePacked(msg.sender, _tenant, _amount, _duration));

    if (insurances[_insuranceId].owner != address(0)) revert InsuranceAlreadyExists();

    insurances[_insuranceId] =
      InsuranceData({owner: msg.sender, tenant: _tenant, amount: _amount, duration: _duration, accepted: false});

    emit InsuranceInitialized(_insuranceId, msg.sender, _tenant, _amount, _duration);
  }

  function cancelInsurance(bytes32 _insuranceId) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner != msg.sender) revert NotOwner();

    delete insurances[_insuranceId];

    emit InsuranceCanceled(_insuranceId);
  }

  function acceptInsurance(bytes32 _insuranceId) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.tenant != msg.sender) revert NotTenant();

    _insurance.accepted = true;

    emit InsuranceAccepted(_insuranceId);
  }
}
