// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IERC4626} from 'oz/interfaces/IERC4626.sol';

/**
 * @title Insurance Pool Contract
 */
interface IInsurancePool is IERC4626 {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  event Locked(uint256 indexed insuranceId, uint256 amount);

  event Unlocked(uint256 indexed insuranceId, uint256 amount);

  event Executed(uint256 indexed insuranceId, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  error InsuranceAlreadyLocked();

  error InsuranceNotLocked();

  error InsufficientFunds();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function totalLocked() external view returns (uint256);

  function amountLocked(uint256 insuranceId) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function lock(uint256 insuranceId, uint256 amount) external;

  function unlock(uint256 insuranceId) external;

  function execute(uint256 insuranceId, uint256 amount) external;
}
