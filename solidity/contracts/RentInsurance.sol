// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Ownable} from 'oz/access/Ownable.sol';
import {IRentInsurance} from 'interfaces/IRentInsurance.sol';
import {IInsurancePool} from 'interfaces/IInsurancePool.sol';
import {IRent} from 'interfaces/IRent.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';
import {ECDSA} from 'oz/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';

contract RentInsurance is IRentInsurance, Ownable {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  /// @inheritdoc IRentInsurance
  address public immutable override SIGNER;

  /// @inheritdoc IRentInsurance
  address public immutable override RENT;

  /// @inheritdoc IRentInsurance
  mapping(uint256 insuranceId => InsuranceData data) public override insurances;

  /// @inheritdoc IRentInsurance
  uint256 public override insuranceCounter;

  constructor(address _signer, address _rent) Ownable(msg.sender) {
    SIGNER = _signer;
    RENT = _rent;
  }

  /// @inheritdoc IRentInsurance
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

  /// @inheritdoc IRentInsurance
  function cancelInsurance(uint256 _insuranceId) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (_insurance.owner != msg.sender) revert NotOwner();
    if (_insurance.accepted) revert InsuranceAlreadyAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();

    _insurance.canceled = true;

    emit InsuranceCanceled(_insuranceId);
  }

  /// @inheritdoc IRentInsurance
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
    IInsurancePool(_pool).lock(_insuranceId, _payment);

    // Initialize the rent
    IRent(RENT).initializeRent(_insuranceId);

    // Transfer the payment to the pool
    IERC20(IInsurancePool(_pool).asset()).transferFrom(msg.sender, _pool, _payment);

    emit InsuranceAccepted(_insuranceId);
  }

  /// @inheritdoc IRentInsurance
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

  /// @inheritdoc IRentInsurance
  function executeInsurance(uint256 _insuranceId, uint256 _amount) external override {
    InsuranceData storage _insurance = insurances[_insuranceId];

    if (msg.sender != owner() && msg.sender != RENT) revert NotOwner();
    if (_insurance.owner == address(0)) revert InsuranceDoesNotExist();
    if (!_insurance.accepted) revert InsuranceNotAccepted();
    if (_insurance.canceled) revert InsuranceAlreadyCanceled();
    if (_insurance.finished) revert InsuranceAlreadyFinished();

    IInsurancePool _pool = IInsurancePool(_insurance.pool);

    _pool.execute(_insuranceId, _amount);

    if (_pool.amountLocked(_insuranceId) == 0) {
      _insurance.finished = true;
      emit InsuranceFinished(_insuranceId);
    }

    IERC20(_pool.asset()).transfer(_insurance.owner, _amount);

    emit InsuranceExecuted(_insuranceId, _amount);
  }
}
