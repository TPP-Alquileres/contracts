// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IntegrationBase, IInsurancePool, IRent} from 'test/integration/IntegrationBase.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';

contract IntegrationRentInsurance is IntegrationBase {
  using MessageHashUtils for bytes32;

  uint256 internal constant INSURANCE_AMOUNT = 1 ether;
  uint256 internal constant INSURANCE_DURATION = 30 days;
  uint256 internal constant INSURANCE_PAYMENT = 0.1 ether;
  uint256 internal constant INSURANCE_EXECUTION = 0.1 ether;

  function test_Insurance() public {
    // Fund the tenant
    deal(address(DAI), _tenant, 0.1 ether, true);

    // Get the current insurance ID
    uint256 _insuranceId = _insurance.insuranceCounter();

    // Initialize the insurance
    vm.prank(_user);
    _insurance.initializeInsurance(INSURANCE_AMOUNT, INSURANCE_DURATION);

    // Get the insurance data
    (address _insuranceOwner,, uint256 _amount,,, uint256 _duration,,,,) = _insurance.insurances(_insuranceId);

    assertEq(_insuranceOwner, _user);
    assertEq(_amount, INSURANCE_AMOUNT);
    assertEq(_duration, INSURANCE_DURATION);

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    // Approve DAI to the insurance contract
    vm.prank(_tenant);
    DAI.approve(address(_insurance), INSURANCE_PAYMENT);

    // Accept the insurance
    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    {
      // Get the insurance data
      (, address _insuranceTenant,, uint256 _payment, address _pool,, uint256 _startDate, bool _accepted,,) =
        _insurance.insurances(_insuranceId);

      assertEq(_insuranceTenant, _tenant);
      assertEq(_payment, INSURANCE_PAYMENT);
      assertEq(_pool, address(_insurancePool));
      assertEq(_startDate, block.timestamp);
      assertTrue(_accepted);
    }

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_PAYMENT);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_PAYMENT);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Try to withdraw the locked amount
    vm.expectRevert(IInsurancePool.InsufficientFunds.selector);
    vm.prank(_investor);
    _insurancePool.withdraw(TOTAL_AMOUNT + 1, _investor, _investor);

    // Advance time to the end of the insurance
    vm.warp(block.timestamp + INSURANCE_DURATION);

    // Finish the insurance
    vm.prank(_owner);
    _insurance.finishInsurance(_insuranceId);

    // Get the insurance data
    (,,,,,,,,, bool finished) = _insurance.insurances(_insuranceId);
    assertTrue(finished);

    // Check that the insurance pool has no locked amount
    assertEq(_insurancePool.totalLocked(), 0);
    assertEq(_insurancePool.amountLocked(_insuranceId), 0);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Check the current investor balance
    uint256 _shares = _insurancePool.balanceOf(_investor);
    uint256 _balance = _insurancePool.convertToAssets(_shares);
    assertApproxEqAbs(_balance, TOTAL_AMOUNT + INSURANCE_PAYMENT, 1);

    // Withdraw the locked amount
    vm.prank(_investor);
    _insurancePool.withdraw(_balance, _investor, _investor);
    assertEq(DAI.balanceOf(_investor), _balance);
  }

  function test_InsuranceExecute() public {
    // Fund the tenant
    deal(address(DAI), _tenant, 0.1 ether, true);

    // Get the current insurance ID
    uint256 _insuranceId = _insurance.insuranceCounter();

    // Initialize the insurance
    vm.prank(_user);
    _insurance.initializeInsurance(INSURANCE_AMOUNT, INSURANCE_DURATION);

    // Get the insurance data
    (address _insuranceOwner,, uint256 _amount,,, uint256 _duration,,,,) = _insurance.insurances(_insuranceId);

    assertEq(_insuranceOwner, _user);
    assertEq(_amount, INSURANCE_AMOUNT);
    assertEq(_duration, INSURANCE_DURATION);

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    // Approve DAI to the insurance contract
    vm.prank(_tenant);
    DAI.approve(address(_insurance), INSURANCE_PAYMENT);

    // Accept the insurance
    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    {
      // Get the insurance data
      (, address _insuranceTenant,, uint256 _payment, address _pool,, uint256 _startDate, bool _accepted,,) =
        _insurance.insurances(_insuranceId);

      assertEq(_insuranceTenant, _tenant);
      assertEq(_payment, INSURANCE_PAYMENT);
      assertEq(_pool, address(_insurancePool));
      assertEq(_startDate, block.timestamp);
      assertTrue(_accepted);
    }

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_PAYMENT);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_PAYMENT);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Execute the insurance
    vm.prank(_owner);
    _insurance.executeInsurance(_insuranceId, INSURANCE_EXECUTION);

    // Get the insurance data
    (,,,,,,,,, bool _finished) = _insurance.insurances(_insuranceId);

    assertTrue(_finished);

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_PAYMENT - INSURANCE_EXECUTION);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_PAYMENT - INSURANCE_EXECUTION);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT - INSURANCE_EXECUTION);

    // Check that the user has the execution amount
    assertEq(DAI.balanceOf(_user), INSURANCE_EXECUTION);
  }

  function test_RentExecute() public {
    // Fund the tenant
    deal(address(DAI), _tenant, 0.1 ether, true);

    // Get the current insurance ID
    uint256 _insuranceId = _insurance.insuranceCounter();

    // Initialize the insurance
    vm.prank(_user);
    _insurance.initializeInsurance(INSURANCE_AMOUNT, INSURANCE_DURATION);

    // Get the insurance data
    (address _insuranceOwner,, uint256 _amount,,, uint256 _duration,,,,) = _insurance.insurances(_insuranceId);

    assertEq(_insuranceOwner, _user);
    assertEq(_amount, INSURANCE_AMOUNT);
    assertEq(_duration, INSURANCE_DURATION);

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    // Approve DAI to the insurance contract
    vm.prank(_tenant);
    DAI.approve(address(_insurance), INSURANCE_PAYMENT);

    // Accept the insurance
    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    {
      // Get the insurance data
      (, address _insuranceTenant,, uint256 _payment, address _pool,, uint256 _startDate, bool _accepted,,) =
        _insurance.insurances(_insuranceId);

      assertEq(_insuranceTenant, _tenant);
      assertEq(_payment, INSURANCE_PAYMENT);
      assertEq(_pool, address(_insurancePool));
      assertEq(_startDate, block.timestamp);
      assertTrue(_accepted);
    }

    // Check that the rent is initialized
    uint256 _nextPayment = _rent.rents(_insuranceId);
    assertEq(_nextPayment, block.timestamp + 30 days);

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_PAYMENT);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_PAYMENT);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Advance time to the next payment
    vm.warp(_nextPayment);

    // Execute the rent should fail
    vm.expectRevert(IRent.RentNotDue.selector);
    vm.prank(_user);
    _rent.collectInsurance(_insuranceId);

    // Advance time to expiration payment
    vm.warp(_nextPayment + 10 days);

    // Execute the rent
    vm.prank(_user);
    _rent.collectInsurance(_insuranceId);

    // Get the insurance data
    (,,,,,,,,, bool _finished) = _insurance.insurances(_insuranceId);

    assertFalse(_finished);

    uint256 _rentPayed = _amount / 12;

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_PAYMENT - _rentPayed);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_PAYMENT - _rentPayed);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT - _rentPayed);

    // Check that the user has the execution amount
    assertEq(DAI.balanceOf(_user), _rentPayed);
  }
}
