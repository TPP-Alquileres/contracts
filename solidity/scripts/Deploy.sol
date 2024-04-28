// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Script} from 'forge-std/Script.sol';
import {RentInsurance} from 'contracts/RentInsurance.sol';
import {MyToken} from 'contracts/MyToken.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

abstract contract Deploy is Script {
  function _deploy() internal {
    vm.startBroadcast();

    IERC20 token = new MyToken();
    new RentInsurance(token);

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
