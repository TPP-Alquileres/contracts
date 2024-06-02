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

  /**
   * @notice Emitted when an insurance is locked
   * @param insuranceId The insurance id
   * @param amount The amount locked
   */
  event Locked(uint256 indexed insuranceId, uint256 amount);

  /**
   * @notice Emitted when an insurance is unlocked
   * @param insuranceId The insurance id
   * @param amount The amount unlocked
   */
  event Unlocked(uint256 indexed insuranceId, uint256 amount);

  /**
   * @notice Emitted when an insurance is executed
   * @param insuranceId The insurance id
   * @param amount The amount executed
   */
  event Executed(uint256 indexed insuranceId, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws when the insurance is already locked
   */
  error InsuranceAlreadyLocked();

  /**
   * @notice Throws when the insurance is not locked
   */
  error InsuranceNotLocked();

  /**
   * @notice Throws when the pool has insufficient funds
   */
  error InsufficientFunds();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The total amount locked in the pool
   * @return The total amount locked
   */
  function totalLocked() external view returns (uint256);

  /**
   * @notice The amount locked for an insurance
   * @param insuranceId The insurance id
   * @return The amount locked
   */
  function amountLocked(uint256 insuranceId) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Locks an amount for an insurance
   * @param insuranceId The insurance id
   * @param amount The amount to lock
   * @dev Only the insurance contract can call this function
   */
  function lock(uint256 insuranceId, uint256 amount) external;

  /**
   * @notice Unlocks an amount for an insurance
   * @param insuranceId The insurance id
   * @dev Only the insurance contract can call this function
   */
  function unlock(uint256 insuranceId) external;

  /**
   * @notice Executes an amount for an insurance
   * @param insuranceId The insurance id
   * @param amount The amount to execute
   * @dev Only the insurance contract can call this function
   */
  function execute(uint256 insuranceId, uint256 amount) external;
}
