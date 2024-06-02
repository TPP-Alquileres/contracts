// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Ownable} from 'oz/access/Ownable.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';
import {InsurancePool, IInsurancePool} from 'contracts/InsurancePool.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';
import {ECDSA} from 'oz/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';

contract RentInsurance is IRentInsurance, Ownable {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  address public immutable SIGNER;

  mapping(uint256 insuranceId => InsuranceData data) public insurances;

  uint256 public insuranceCounter;

  constructor(address _signer) Ownable(msg.sender) {
    SIGNER = _signer;
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
      payment: 0,
      pool: address(0),
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

  function acceptInsurance(
    uint256 _insuranceId,
    uint256 _payment,
    address _pool,
    bytes calldata signature
  ) external override {
    // Verify the signature
    bytes32 _messageHash = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _insuranceId, _payment, _pool))));
    bytes32 _ethSignedMessageHash = _messageHash.toEthSignedMessageHash();
    address _recoveredSigner = _ethSignedMessageHash.recover(signature);
    if (_recoveredSigner != SIGNER) revert InvalidSigner();

    InsuranceData storage _insurance = insurances[_insuranceId];

    // Check if the insurance is valid
    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner == msg.sender) revert NotTenant();
    if (_insurance.accepted) revert InsuranceAlreadyAccepted();

    // Set the insurance as accepted
    _insurance.tenant = msg.sender;
    _insurance.accepted = true;
    _insurance.startDate = block.timestamp;
    _insurance.payment = _payment;
    _insurance.pool = _pool;

    // Lock the insurance amount in the pool
    IInsurancePool(_pool).lock(_insuranceId, _insurance.amount);

    // Transfer the payment to the pool
    IERC20(IInsurancePool(_pool).asset()).transferFrom(msg.sender, _pool, _payment);

    emit InsuranceAccepted(_insuranceId);
  }

  function finishInsurance(uint256 _insuranceId) external override onlyOwner {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (!_insurance.accepted) revert InsuranceNotAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();
    if (_insurance.finished) revert InsuranceAlreadyFinished();
    if (block.timestamp < _insurance.startDate + _insurance.duration) revert InsuranceNotFinished();

    _insurance.finished = true;

    IInsurancePool(_insurance.pool).unlock(_insuranceId);

    emit InsuranceFinished(_insuranceId);
  }

  function executeInsurance(uint256 _insuranceId, uint256 _amount) external override onlyOwner {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (!_insurance.accepted) revert InsuranceNotAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();
    if (_insurance.finished) revert InsuranceAlreadyFinished();

    _insurance.amount -= _amount;

    IInsurancePool(_insurance.pool).execute(_insuranceId, _amount);

    IERC20(IInsurancePool(_insurance.pool).asset()).transfer(_insurance.owner, _amount);

    emit InsuranceExecuted(_insuranceId, _amount);
  }
}
