// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IntegrationBase, IInsurancePool} from 'test/integration/IntegrationBase.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';

contract IntegrationRentInsurance is IntegrationBase {
  using MessageHashUtils for bytes32;

  uint256 internal constant INSURANCE_AMOUNT = 1 ether;
  uint256 internal constant INSURANCE_DURATION = 30 days;
  uint256 internal constant INSURANCE_PAYMENT = 0.1 ether;
  uint256 internal constant INSURANCE_EXECUTION = 0.2 ether;

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
    assertEq(_insurancePool.totalLocked(), INSURANCE_AMOUNT);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_AMOUNT);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Try to withdraw the locked amount
    vm.expectRevert(IInsurancePool.InsufficientFunds.selector);
    vm.prank(_investor);
    _insurancePool.withdraw(TOTAL_AMOUNT, _investor, _investor);

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
    assertEq(_insurancePool.totalLocked(), INSURANCE_AMOUNT);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_AMOUNT);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT);

    // Execute the insurance
    vm.prank(_owner);
    _insurance.executeInsurance(_insuranceId, INSURANCE_EXECUTION);

    // Get the insurance data
    (,, uint256 _newAmount,,,,,,,) = _insurance.insurances(_insuranceId);

    assertEq(_newAmount, INSURANCE_AMOUNT - INSURANCE_EXECUTION);

    // Check that the insurance pool has the locked amount
    assertEq(_insurancePool.totalLocked(), INSURANCE_AMOUNT - INSURANCE_EXECUTION);
    assertEq(_insurancePool.amountLocked(_insuranceId), INSURANCE_AMOUNT - INSURANCE_EXECUTION);
    assertEq(DAI.balanceOf(address(_insurancePool)), TOTAL_AMOUNT + INSURANCE_PAYMENT - INSURANCE_EXECUTION);

    // Check that the user has the execution amount
    assertEq(DAI.balanceOf(_user), INSURANCE_EXECUTION);
  }
}
