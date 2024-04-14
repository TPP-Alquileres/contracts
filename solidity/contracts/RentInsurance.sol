// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Ownable} from 'oz/access/Ownable.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';
import {InsurancePool, IInsurancePool} from 'contracts/InsurancePool.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

contract RentInsurance is IRentInsurance, Ownable {
  mapping(uint256 insuranceId => InsuranceData data) public insurances;

  uint256 public insuranceCounter;

  IInsurancePool public insurancePool;

  constructor(IERC20 _token) {
    insurancePool = new InsurancePool(_token, 'Rent Insurance Pool', 'RIP');
  }

  function initializeInsurance(uint256 _amount, uint256 _duration) external override {
    if (_amount == 0) revert InvalidAmount();
    if (_duration == 0) revert InvalidDuration();

    uint256 _insuranceId = insuranceCounter++;

    if (insurances[_insuranceId].owner != address(0)) revert InsuranceAlreadyExists();

    insurances[_insuranceId] = InsuranceData({
      owner: msg.sender,
      tenant: address(0),
      amount: _amount,
      duration: _duration,
      startDate: 0,
      accepted: false,
      canceled: false,
      finished: false
    });

    emit InsuranceInitialized(_insuranceId, msg.sender, _amount, _duration);
  }

  function cancelInsurance(uint256 _insuranceId) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner != msg.sender) revert NotOwner();
    if (_insurance.accepted) revert InsuranceAlreadyAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();

    _insurance.canceled = true;

    emit InsuranceCanceled(_insuranceId);
  }

  function acceptInsurance(uint256 _insuranceId) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner == msg.sender) revert NotTenant();
    if (_insurance.accepted) revert InsuranceAlreadyAccepted();

    _insurance.tenant = msg.sender;
    _insurance.accepted = true;
    _insurance.startDate = block.timestamp;

    insurancePool.lock(_insuranceId, _insurance.amount);

    emit InsuranceAccepted(_insuranceId);
  }

  function finishInsurance(uint256 _insuranceId) external override onlyOwner {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner != msg.sender) revert NotOwner();
    if (!_insurance.accepted) revert InsuranceNotAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();
    if (_insurance.finished) revert InsuranceAlreadyFinished();
    if (block.timestamp < _insurance.startDate + _insurance.duration) revert InsuranceNotFinished();

    _insurance.finished = true;

    insurancePool.unlock(_insuranceId);

    emit InsuranceFinished(_insuranceId);
  }
}
