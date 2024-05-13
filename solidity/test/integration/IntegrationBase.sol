// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';

import {RentInsurance, IRentInsurance} from 'contracts/RentInsurance.sol';
import {InsurancePool, IInsurancePool} from 'contracts/InsurancePool.sol';

contract IntegrationBase is Test {
  uint256 internal constant _FORK_BLOCK = 19_838_790;
  uint256 internal constant TOTAL_AMOUNT = 100 ether;
  uint256 public constant SIGNER_PK = 0x123;

  address internal _owner = makeAddr('owner');
  address internal _user = makeAddr('user');
  address internal _tenant = makeAddr('tenant');
  address internal _investor = makeAddr('investor');
  address internal _signer = vm.addr(SIGNER_PK);

  IERC20 internal _dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  IRentInsurance internal _insurance;
  IInsurancePool internal _insurancePool;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), _FORK_BLOCK);

    // Deploy the insurance contract
    vm.prank(_owner);
    _insurance = new RentInsurance(_dai, _signer);

    // Fund the insurance pool
    vm.startPrank(_investor);
    _insurancePool = _insurance.INSURANCE_POOL();
    deal(address(_dai), _investor, TOTAL_AMOUNT, true);
    _dai.approve(address(_insurancePool), TOTAL_AMOUNT);
    _insurancePool.deposit(TOTAL_AMOUNT, _investor);
    assertEq(_insurancePool.balanceOf(_investor), TOTAL_AMOUNT);
    vm.stopPrank();
  }
}
