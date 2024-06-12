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

contract UnitRent is Base {
  function test_RentInsurance() public {
    assertEq(address(_rent.RENT_INSURANCE()), address(_insurance));
  }

  function test_InitializeRent() public {
    vm.prank(address(_insurance));
    _rent.initializeRent(1);

    uint256 _nextPayment = _rent.rents(1);

    assertEq(_nextPayment, block.timestamp + 30 days);
  }

  function test_PayRent() public {
    vm.prank(address(_insurance));
    _rent.initializeRent(1);

    uint256 _lastPayment = _rent.rents(1);
    vm.warp(_lastPayment);

    // Mock insurance
    vm.mockCall(
      address(_insurance),
      abi.encodeWithSelector(IRentInsurance.insurances.selector, 1),
      abi.encode(
        _user, _tenant, 1 ether, 0.1 ether, address(_insurancePool), 30 days, block.timestamp, false, false, false
      )
    );

    deal(address(_token), _tenant, 1 ether, true);

    vm.prank(_tenant);
    _token.approve(address(_rent), 1 ether);

    vm.prank(_tenant);
    _rent.payRent(1);

    uint256 _nextPayment = _rent.rents(1);

    assertEq(_nextPayment, _lastPayment + 30 days);
  }

  function test_CollectInsurance() public {
    vm.prank(address(_insurance));
    _rent.initializeRent(1);

    // Mock insurance
    vm.mockCall(
      address(_insurance),
      abi.encodeWithSelector(IRentInsurance.insurances.selector, 1),
      abi.encode(
        _user, _tenant, 1 ether, 0.1 ether, address(_insurancePool), 30 days, block.timestamp, false, false, false
      )
    );

    vm.warp(block.timestamp + 40 days);

    // Mock insurance
    vm.mockCall(address(_insurance), abi.encodeWithSelector(IRentInsurance.executeInsurance.selector), abi.encode(true));
    vm.expectCall(address(_insurance), abi.encodeWithSelector(IRentInsurance.executeInsurance.selector));

    vm.prank(_user);
    _rent.collectInsurance(1);
  }
}
