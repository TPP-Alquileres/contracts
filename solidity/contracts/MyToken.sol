// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {ERC20} from 'oz/token/ERC20/ERC20.sol';
import {Ownable} from 'oz/access/Ownable.sol';
import {ERC20Permit} from 'oz/token/ERC20/extensions/ERC20Permit.sol';

contract MyToken is ERC20, Ownable, ERC20Permit {
  constructor() ERC20('MyToken', 'MTK') ERC20Permit('MyToken') {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}
