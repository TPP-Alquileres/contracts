// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**
 * @title Rent Insurance Contract
 */
interface IRentInsurance {
  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  //////////////////////////////////////////////////////////////*/

  struct InsuranceData {
    address owner;
    address tenant;
    uint256 amount;
    uint256 duration;
    bool accepted;
  }

  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  event InsuranceInitialized(
    bytes32 indexed insuranceId, address indexed owner, address indexed tenant, uint256 amount, uint256 duration
  );

  event InsuranceCanceled(bytes32 indexed insuranceId);

  event InsuranceAccepted(bytes32 indexed insuranceId);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidAddress();

  error InvalidAmount();

  error InvalidDuration();

  error InsuranceAlreadyExists();

  error InsuranceDoesNotExist();

  error NotOwner();

  error NotTenant();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function insurances(bytes32 insuranceId)
    external
    view
    returns (address owner, address tenant, uint256 amount, uint256 duration, bool accepted);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function initializeInsurance(address _tenant, uint256 _amount, uint256 _duration) external;

  function cancelInsurance(bytes32 _insuranceId) external;

  function acceptInsurance(bytes32 _insuranceId) external;
}
