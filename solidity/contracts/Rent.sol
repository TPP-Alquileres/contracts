// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IRent} from 'interfaces/IRent.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';
import {IInsurancePool} from 'contracts/InsurancePool.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

contract Rent is IRent {
  /// @inheritdoc IRent
  IRentInsurance public immutable override RENT_INSURANCE;

  /// @inheritdoc IRent
  mapping(uint256 insuranceId => RentData rent) public override rents;

  constructor(address _rentInsurance) {
    RENT_INSURANCE = IRentInsurance(_rentInsurance);
  }

  /// @inheritdoc IRent
  function initializeRent(uint256 _insuranceId) external override {
    if (msg.sender != address(RENT_INSURANCE)) revert NotAuthorized();

    rents[_insuranceId].nextPayment = block.timestamp + 30 days;

    emit RentInitialized(_insuranceId);
  }

  /// @inheritdoc IRent
  function payRent(uint256 _insuranceId) external override {
    RentData storage _rent = rents[_insuranceId];

    if (_rent.nextPayment > block.timestamp) revert RentNotDue();

    _rent.nextPayment += 30 days;

    (address _owner,, uint256 _amount,, address _pool,,,,,) = RENT_INSURANCE.insurances(_insuranceId);

    uint256 _payment = _amount / 12;

    IERC20(IInsurancePool(_pool).asset()).transferFrom(msg.sender, _owner, _payment);

    emit RentPaid(_insuranceId, _payment);
  }

  /// @inheritdoc IRent
  function collectInsurance(uint256 _insuranceId) external override {
    (address _owner,, uint256 _amount,,,,,,,) = RENT_INSURANCE.insurances(_insuranceId);

    if (msg.sender != _owner) revert NotAuthorized();

    RentData storage _rent = rents[_insuranceId];

    if (_rent.nextPayment + 10 days > block.timestamp) revert RentNotDue();

    uint256 _payment = _amount / 12;

    RENT_INSURANCE.executeInsurance(_insuranceId, _payment);
  }
}
