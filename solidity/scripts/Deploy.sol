// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from 'forge-std/Script.sol';
import {RentInsurance} from 'contracts/RentInsurance.sol';
import {InsurancePool} from 'contracts/InsurancePool.sol';
import {MyToken} from 'contracts/MyToken.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

abstract contract Deploy is Script {
  function _deploy() internal {
    vm.startBroadcast();

    IERC20 token = new MyToken();
    RentInsurance _insurance = new RentInsurance(msg.sender);
    new InsurancePool(token, 'Rent Insurance Pool', 'RIP', address(_insurance));

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
