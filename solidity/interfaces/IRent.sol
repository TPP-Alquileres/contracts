// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IRentInsurance} from 'interfaces/IRentInsurance.sol';

/**
 * @title Rent Contract
 */
interface IRent {
  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Rent data
   * @param insuranceId The insurance ID
   */
  struct RentData {
    uint256 nextPayment;
  }

  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a rent is initialized
   * @param insuranceId The insurance ID
   */
  event RentInitialized(uint256 indexed insuranceId);

  /**
   * @notice Emitted when a rent is paid
   * @param insuranceId The insurance ID
   * @param amount The amount paid
   */
  event RentPaid(uint256 indexed insuranceId, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws if the caller is not authorized
   */
  error NotAuthorized();

  /**
   * @notice Throws if the rent is not due
   */
  error RentNotDue();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The rent insurance contract
   */
  function RENT_INSURANCE() external view returns (IRentInsurance);

  /**
   * @notice The rents
   * @param insuranceId The insurance ID
   * @return nextPayment The next payment date
   */
  function rents(uint256 insuranceId) external view returns (uint256 nextPayment);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializes a new rent
   * @param _insuranceId The insurance ID associated
   */
  function initializeRent(uint256 _insuranceId) external;

  /**
   * @notice Pays the rent
   * @param _insuranceId The insurance ID associated
   * @dev The rent is due every 30 days
   */
  function payRent(uint256 _insuranceId) external;

  /**
   * @notice Collects the insurance
   * @param _insuranceId The insurance ID associated
   * @dev The insurance can be collected 10 days after the last payment is due
   * @dev The rent owner can collect the insurance
   */
  function collectInsurance(uint256 _insuranceId) external;
}
