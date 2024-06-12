// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

import {RentInsurance, IRentInsurance} from 'contracts/RentInsurance.sol';
import {Rent, IRent} from 'contracts/Rent.sol';
import {InsurancePool, IInsurancePool} from 'contracts/InsurancePool.sol';
import {MyToken} from 'contracts/MyToken.sol';
import {MessageHashUtils} from 'oz/utils/cryptography/MessageHashUtils.sol';

abstract contract Base is Test {
  uint256 internal constant TOTAL_AMOUNT = 100 ether;
  uint256 public constant SIGNER_PK = 0x123;

  address internal _owner = makeAddr('owner');
  address internal _user = makeAddr('user');
  address internal _tenant = makeAddr('tenant');
  address internal _investor = makeAddr('investor');
  address internal _signer = vm.addr(SIGNER_PK);

  IRentInsurance internal _insurance;
  IInsurancePool internal _insurancePool;
  IRent internal _rent;
  MyToken internal _token;

  function setUp() public virtual {
    // Deploy contracts
    vm.startPrank(_owner);

    // Deploy the insurance contract
    uint256 _nonce = vm.getNonce(_owner);
    address _rentAddress = computeCreateAddress(_owner, _nonce + 1);
    _insurance = new RentInsurance(_signer, _rentAddress);

    // Deploy the rent contract
    _rent = new Rent(address(_insurance));

    assertEq(_rentAddress, address(_rent));

    // Deploy the insurance pool
    _token = new MyToken();
    _insurancePool = new InsurancePool(_token, 'Rent Insurance Pool', 'RIP', address(_insurance));
    vm.stopPrank();

    // Fund the insurance pool
    vm.startPrank(_investor);
    deal(address(_token), _investor, TOTAL_AMOUNT, true);
    _token.approve(address(_insurancePool), TOTAL_AMOUNT);
    _insurancePool.deposit(TOTAL_AMOUNT, _investor);
    assertEq(_insurancePool.balanceOf(_investor), TOTAL_AMOUNT);
    vm.stopPrank();
  }
}
