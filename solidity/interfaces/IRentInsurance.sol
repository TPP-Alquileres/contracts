// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

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
    uint256 payment;
    address pool;
    uint256 duration;
    uint256 startDate;
    bool accepted;
    bool canceled;
    bool finished;
  }

  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  event InsuranceInitialized(uint256 indexed insuranceId, address indexed owner, uint256 amount, uint256 duration);

  event InsuranceCanceled(uint256 indexed insuranceId);

  event InsuranceAccepted(uint256 indexed insuranceId);

  event InsuranceFinished(uint256 indexed insuranceId);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidAddress();

  error InvalidAmount();

  error InvalidDuration();

  error InsuranceAlreadyExists();

  error InsuranceDoesNotExist();

  error InsuranceNotAccepted();

  error InsuranceAlreadyAccepted();

  error InsuranceAlreadyCanceled();

  error InsuranceAlreadyFinished();

  error InsuranceNotFinished();

  error NotOwner();

  error NotTenant();

  error InvalidSigner();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function insurances(uint256 insuranceId)
    external
    view
    returns (
      address owner,
      address tenant,
      uint256 amount,
      uint256 payment,
      address pool,
      uint256 duration,
      uint256 startDate,
      bool accepted,
      bool canceled,
      bool finished
    );

  function insuranceCounter() external view returns (uint256);

  function SIGNER() external view returns (address);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  function initializeInsurance(uint256 _amount, uint256 _duration) external;

  function cancelInsurance(uint256 _insuranceId) external;

  function acceptInsurance(uint256 _insuranceId, uint256 _payment, address _pool, bytes calldata signature) external;

  function finishInsurance(uint256 _insuranceId) external;
}
