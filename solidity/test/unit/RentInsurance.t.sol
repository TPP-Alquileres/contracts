// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

import {RentInsurance, IRentInsurance} from 'contracts/RentInsurance.sol';
import {Rent, IRent} from 'contracts/Rent.sol';
import {InsurancePool, IInsurancePool} from 'contracts/InsurancePool.sol';
import {MyToken} from 'contracts/MyToken.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';
import {Base} from 'test/unit/Base.sol';

contract UnitRentInsurance is Base {
  using MessageHashUtils for bytes32;

  function test_Signer() public {
    assertEq(_insurance.SIGNER(), _signer);
  }

  function test_Rent() public {
    assertEq(_insurance.RENT(), address(_rent));
  }

  function test_InitializeInsurance() public {
    uint256 _insuranceId = _insurance.insuranceCounter();
    vm.prank(_user);
    _insurance.initializeInsurance(1 ether, 30 days);

    (address _insuranceOwner,, uint256 _amount,,, uint256 _duration,,,,) = _insurance.insurances(_insuranceId);

    assertEq(_insuranceOwner, _user);
    assertEq(_amount, 1 ether);
    assertEq(_duration, 30 days);
  }

  function test_CancelInsurance() public {
    uint256 _insuranceId = _insurance.insuranceCounter();
    vm.prank(_user);
    _insurance.initializeInsurance(1 ether, 30 days);

    vm.prank(_user);
    _insurance.cancelInsurance(_insuranceId);

    (,,,,,,,, bool _canceled,) = _insurance.insurances(_insuranceId);

    assertTrue(_canceled);
  }

  function test_AcceptInsurance() public {
    uint256 _insuranceId = _insurance.insuranceCounter();
    vm.prank(_user);
    _insurance.initializeInsurance(1 ether, 30 days);

    uint256 INSURANCE_PAYMENT = 1 ether;

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    deal(address(_token), _tenant, INSURANCE_PAYMENT, true);

    vm.prank(_tenant);
    _token.approve(address(_insurance), INSURANCE_PAYMENT);

    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    (, address _insuranceTenant,, uint256 _payment, address _pool,, uint256 _startDate, bool _accepted,,) =
      _insurance.insurances(_insuranceId);

    assertEq(_insuranceTenant, _tenant);
    assertEq(_payment, INSURANCE_PAYMENT);
    assertEq(_pool, address(_insurancePool));
    assertEq(_startDate, block.timestamp);
    assertTrue(_accepted);
  }

  function test_FinishInsurance() public {
    uint256 _insuranceId = _insurance.insuranceCounter();
    vm.prank(_user);
    _insurance.initializeInsurance(1 ether, 30 days);

    uint256 INSURANCE_PAYMENT = 1 ether;

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    deal(address(_token), _tenant, INSURANCE_PAYMENT, true);

    vm.prank(_tenant);
    _token.approve(address(_insurance), INSURANCE_PAYMENT);

    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    // Advance time
    vm.warp(block.timestamp + 30 days);

    vm.prank(_owner);
    _insurance.finishInsurance(_insuranceId);

    (,,,,,,,,, bool _finished) = _insurance.insurances(_insuranceId);

    assertTrue(_finished);
  }

  function test_ExecuteInsurance() public {
    uint256 _insuranceId = _insurance.insuranceCounter();
    vm.prank(_user);
    _insurance.initializeInsurance(1 ether, 30 days);

    uint256 INSURANCE_PAYMENT = 1 ether;

    // Generate the signature
    bytes32 digest = keccak256(
      bytes.concat(keccak256(abi.encode(_tenant, _insuranceId, INSURANCE_PAYMENT, address(_insurancePool))))
    ).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    deal(address(_token), _tenant, INSURANCE_PAYMENT, true);

    vm.prank(_tenant);
    _token.approve(address(_insurance), INSURANCE_PAYMENT);

    vm.prank(_tenant);
    _insurance.acceptInsurance(_insuranceId, INSURANCE_PAYMENT, address(_insurancePool), _signature);

    vm.prank(_owner);
    _insurance.executeInsurance(_insuranceId, INSURANCE_PAYMENT);

    (,,,,,,,,, bool _finished) = _insurance.insurances(_insuranceId);
    assertTrue(_finished);

    assertEq(_token.balanceOf(_user), INSURANCE_PAYMENT);
  }
}
