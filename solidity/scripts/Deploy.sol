// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from 'forge-std/Script.sol';
import {RentInsurance} from 'contracts/RentInsurance.sol';
import {Rent} from 'contracts/Rent.sol';
import {InsurancePool} from 'contracts/InsurancePool.sol';
import {MyToken} from 'contracts/MyToken.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

abstract contract Deploy is Script {
  function _deploy() internal {
    vm.startBroadcast();

    // Deploy mock ERC20 token
    IERC20 token = new MyToken();

    // Deploy Rent Insurance contract
    uint256 _nonce = vm.getNonce(msg.sender);
    address _rentAddress = computeCreateAddress(msg.sender, _nonce + 1);
    RentInsurance _insurance = new RentInsurance(msg.sender, _rentAddress);

    // Deploy Rent contract
    new Rent(address(_insurance));

    // Deploy insurance pools contracts
    new InsurancePool(token, 'Rent Insurance Pool (Low risk)', 'RIP-LR', address(_insurance));
    new InsurancePool(token, 'Rent Insurance Pool (Medium risk)', 'RIP-MR', address(_insurance));
    new InsurancePool(token, 'Rent Insurance Pool (High risk)', 'RIP-HR', address(_insurance));

    vm.stopBroadcast();
  }
}

contract DeployMainnet is Deploy {
  function run() external {
    _deploy();
  }
}

contract DeployGoerli is Deploy {
  function run() external {
    _deploy();
  }
}

contract DeploySepolia is Deploy {
  function run() external {
    _deploy();
  }
}
