// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./FlightSuretyData.sol";

contract FlightSuretyDataImpl is FlightSuretyData {

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    // Airlines Resource
    struct Airline {
        uint id;
        bool isVoter;
    }
    uint public airlinesCount;
    mapping(address => Airline) public airlines;
    event AirlineRegistered(address airlineAddress);
    event AirlineIsVoterUpdate(address airlineAddress, bool isVoter);

    // Flight Resource
    uint public flightCount;
    enum FlightState{AvailableForInsurance, NotAvailableForInsurance}
    struct Flight {
        uint id;
        string flight;
        bytes32 key;
        address airlineAddress;
        FlightState state;
        uint departureTimestamp;
        uint8 departureStatusCode;
        uint updatedTimestamp;
    }
    mapping(uint => Flight) private flights;
    mapping(bytes32 => uint) flightKeyToId;
    event FlightAvailableForInsurance(uint id);
    event FlightIsNotAvailableForInsurance(uint id);
    event FlightDepartureStatusCodeUpdated(uint id, uint8 statusCode);

    // Insurance Resource
    uint public insuranceCount;
    enum InsuranceState {Active, Expired, Credited}
    struct Insurance {
        uint id;
        uint flightId;
        InsuranceState state;
        uint amountPaid;
        address owner;
    }
    mapping(uint => Insurance) public insurancesById;
    mapping(address => uint[]) private passengerToInsurances;
    mapping(uint => uint[]) private flightToInsurances;
    event InsuranceActive(uint id);
    event InsuranceCredited(uint id);
    event InsuranceExpired(uint id);

    // Credited Amount Resource
    mapping(address => uint) public creditedAmounts;
    event AmountWithdrawn(address _address, uint amountWithdrawn);

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(){
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational(){
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner(){
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier verifyAirlineExists(address _address){
        require(airlines[_address].id > 0, "Airline with given address does not exists");
        _;
    }

    modifier verifyFlightExists(uint _id)
    {
        require(flights[_id].id > 0, "Flight does not exists in the system");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool){
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline()external pure {
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy( )external payable {
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees()external   pure {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay()external pure {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund()public payable{
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32){
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }



    // Implement all the required functions
    function setIsAuthorizedCaller(address _address, bool isAuthorized) public override {
        // Implementation
    }

    function createAirline(address airlineAddress, bool isVoter) public override {
        // Implementation
    }

    function addFunds(uint _funds) public override {
        // Implementation
    }

    function getAirlinesCount() public view override returns (uint) {
        // Implementation
        return 0;
    }

    function createInsurance(uint _flightId, uint _amountPaid, address _owner) public override {
        // Implementation
    }

    function getInsurance(uint _id) public view override returns (uint id, uint flightId, string memory state, uint amountPaid, address owner) {
        // Implementation
        return (0, 0, "", 0, address(0));
    }

    function createFlight(string memory _code, uint _departureTimestamp, address _airlineAddress) public override {
        // Implementation
    }

    function getFlight(uint _id) public view override returns (string memory code, uint departureTimestamp, uint8 departureStatusCode, uint updated) {
        // Implementation
        return ("", 0, 0, 0);
    }

    function getInsurancesByFlight(uint _flightId) requireIsOperational() verifyFlightExists(_flightId)
    public
    view
    override
    returns (uint [] memory)
    {
        return flightToInsurances[_flightId];
    }

    function creditInsurance(uint _id, uint _amountToCredit) public override {
        // Implementation
    }

    function getAirline(address _address) requireIsOperational verifyAirlineExists(_address)
    public
    view
    override
    returns (address airlineAddress, uint id, bool isVoter){
        airlineAddress = _address;
        id = airlines[_address].id;
        isVoter = airlines[_address].isVoter;
    }

    function setAirlineIsVoter(address _address, bool isVoter) public override {
        // Implementation
    }

    function setDepartureStatusCode(uint _flightId, uint8 _statusCode) public override {
        // Implementation
    }

    function setUnavailableForInsurance(uint flightId) public override {
        // Implementation
    }

    function getFlightIdByKey(bytes32 key) public view override returns (uint) {
        // Implementation
        return 0;
    }

    function createFlightKey(address _airlineAddress, string memory flightCode, uint timestamp) public override returns (bytes32) {
        // Implementation
        return bytes32(0);
    }

    function withdrawCreditedAmount(uint _amountToWithdraw, address _address) public override payable {
        // Implementation
    }

    function getCreditedAmount(address _address) public view override returns (uint) {
        return creditedAmounts[_address];
    }
}

