// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/**
 * @title Rent Insurance Contract
 */
interface IRentInsurance {
  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Insurance data
   * @param owner The owner of the insurance
   * @param tenant The tenant of the insurance
   * @param amount The total amount covered by the insurance
   * @param payment The tenant payment required to accept the insurance
   * @param pool The insurance pool address
   * @param duration The duration of the insurance
   * @param startDate The start date of the insurance
   * @param accepted The insurance acceptance status
   * @param canceled The insurance cancelation status
   * @param finished The insurance finish status
   */
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

  /**
   * @notice Emitted when an insurance is initialized
   * @param insuranceId The insurance ID
   * @param owner The owner of the insurance
   * @param amount The total amount covered by the insurance
   * @param duration The duration of the insurance
   */
  event InsuranceInitialized(uint256 indexed insuranceId, address indexed owner, uint256 amount, uint256 duration);

  /**
   * @notice Emitted when an insurance is canceled
   * @param insuranceId The insurance ID
   */
  event InsuranceCanceled(uint256 indexed insuranceId);

  /**
   * @notice Emitted when an insurance is accepted
   * @param insuranceId The insurance ID
   */
  event InsuranceAccepted(uint256 indexed insuranceId);

  /**
   * @notice Emitted when an insurance is canceled
   * @param insuranceId The insurance ID
   */
  event InsuranceFinished(uint256 indexed insuranceId);

  /**
   * @notice Emitted when an insurance is executed
   * @param insuranceId The insurance ID
   * @param amount The amount executed
   */
  event InsuranceExecuted(uint256 indexed insuranceId, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                            ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Throws when the address is invalid
   */
  error InvalidAddress();

  /**
   * @notice Throws when the amount is invalid
   */
  error InvalidAmount();

  /**
   * @notice Throws when the duration is invalid
   */
  error InvalidDuration();

  /**
   * @notice Throws when the insurance already exists
   */
  error InsuranceAlreadyExists();

  /**
   * @notice Throws when the insurance does not exist
   */
  error InsuranceDoesNotExist();

  /**
   * @notice Throws when the insurance is not accepted
   */
  error InsuranceNotAccepted();

  /**
   * @notice Throws when the insurance is already accepted
   */
  error InsuranceAlreadyAccepted();

  /**
   * @notice Throws when the insurance is already canceled
   */
  error InsuranceAlreadyCanceled();

  /**
   * @notice Throws when the insurance is already finished
   */
  error InsuranceAlreadyFinished();

  /**
   * @notice Throws when the insurance is not finished
   */
  error InsuranceNotFinished();

  /**
   * @notice Throws when the sender is not the owner
   */
  error NotOwner();

  /**
   * @notice Throws when the sender is not the tenant
   */
  error NotTenant();

  /**
   * @notice Throws when the signature is invalid
   */
  error InvalidSigner();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The insurances
   */
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

  /**
   * @notice The insurance counter
   * @return The current counter
   */
  function insuranceCounter() external view returns (uint256);

  /**
   * @notice The insurance signer
   * @return The signer address
   */
  function SIGNER() external view returns (address);

  /**
   * @notice The rent contract address
   * @return The rent contract address
   */
  function RENT() external view returns (address);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializes a new insurance
   * @param _amount The total amount covered by the insurance
   * @param _duration The duration of the insurance
   * @dev The insurance ID is the insurance counter
   */
  function initializeInsurance(uint256 _amount, uint256 _duration) external;

  /**
   * @notice Cancels an insurance
   * @param _insuranceId The insurance ID
   * @dev Only the insurance owner can call this function
   */
  function cancelInsurance(uint256 _insuranceId) external;

  /**
   * @notice Accepts an insurance
   * @param _insuranceId The insurance ID
   * @param _payment The tenant payment required to accept the insurance
   * @param _pool The insurance pool address
   * @param signature The signature of signer
   * @dev The tenant must approve the payment before calling this function
   * @dev The signature must be generated by the signer
   * @dev The pool must have enough funds to lock the insurance amount
   */
  function acceptInsurance(uint256 _insuranceId, uint256 _payment, address _pool, bytes calldata signature) external;

  /**
   * @notice Finishes an insurance
   * @param _insuranceId The insurance ID
   * @dev Only the contract owner can call this function
   */
  function finishInsurance(uint256 _insuranceId) external;

  /**
   * @notice Executes an insurance
   * @param _insuranceId The insurance ID
   * @param _amount The amount executed
   * @dev Only the contract owner can call this function
   */
  function executeInsurance(uint256 _insuranceId, uint256 _amount) external;
}
