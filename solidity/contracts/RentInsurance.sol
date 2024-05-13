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

  mapping(uint256 insuranceId => InsuranceData data) public insurances;

  uint256 public insuranceCounter;

  address public signer;

  IInsurancePool public immutable INSURANCE_POOL;

  constructor(IERC20 _token, address _signer) Ownable(msg.sender) {
    INSURANCE_POOL = new InsurancePool(_token, 'Rent Insurance Pool', 'RIP');
    signer = _signer;
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

  function acceptInsurance(uint256 _insuranceId, uint256 _payment, bytes calldata signature) external override {
    // Verify the signature
    bytes32 _messageHash = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _insuranceId, _payment))));
    bytes32 _ethSignedMessageHash = _messageHash.toEthSignedMessageHash();
    address _recoveredSigner = _ethSignedMessageHash.recover(signature);
    if (_recoveredSigner != signer) revert InvalidSigner();

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

    // Lock the insurance amount in the pool
    INSURANCE_POOL.lock(_insuranceId, _insurance.amount);

    // Transfer the payment to the pool
    IERC20(INSURANCE_POOL.asset()).transferFrom(msg.sender, address(INSURANCE_POOL), _payment);

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

    INSURANCE_POOL.unlock(_insuranceId);

    emit InsuranceFinished(_insuranceId);
  }
}
