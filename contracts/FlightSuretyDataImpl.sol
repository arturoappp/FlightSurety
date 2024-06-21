// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./FlightSuretyData.sol";

contract FlightSuretyDataImpl is FlightSuretyData {

    address private appContract;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

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

    uint256 private totalReceivedEther = 0; // Track total received Ether

    constructor() {
        airlines[contractOwner] = true;
        numAirlines = 1;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    //Airline
    modifier onlyRegisteredAirline() {
        require(airlines[msg.sender], "Only existing airline can register new airlines.");
        _;
    }

    modifier verifyFlightExists(uint _id)
    {
        require(flights[_id].id > 0, "Flight does not exists in the system");
        _;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


    function authorizeCaller(address appAddress) external requireContractOwner {
        appContract = appAddress;
    }

    //AIRLINE

    function isAirlineRegistered(address _airline) external view override returns (bool) {
        return airlines[_airline];
    }

    function getNumAirlines() external view override returns (uint256) {
        return numAirlines;
    }

    function getAirlineVotes(address _airline) external view override returns (uint256) {
        return airlineVotes[_airline].length;
    }

    function registerAirline(address _newAirline) external override {
        require(msg.sender == appContract, "Caller is not authorized");
        airlines[_newAirline] = true;
        numAirlines += 1;
        emit AirlineRegistered(_newAirline); // Emit the event
    }

    function voteToRegisterAirline(address _newAirline, address _voter) external override {
        require(msg.sender == appContract, "Caller is not authorized");
        airlineVotes[_newAirline].push(_voter);
    }

    function fundAirline(address _airline) external payable override {
        require(msg.sender == appContract, "Caller is not authorized");
        require(msg.value == 10 ether, "Funding requires 10 ether.");
        funds[_airline] += msg.value;
        emit AirlineFunded(_airline); // Emit the event
    }

    function isFunded(address _airline) external view override returns (bool) {
        return funds[_airline] >= 10 ether;
    }

    // Passenger-related functions
    function buyInsurance(address passenger, bytes32 flightKey, uint256 amount) external payable override {
        require(msg.sender == appContract, "Caller is not authorized");
        insurances[flightKey] = Insurance({
            passenger: passenger,
            amount: amount,
            credited: false
        });

        emit InsurancePurchased(passenger, flightKey, amount);
    }

    function creditInsurees(bytes32 flightKey) external override {
        require(msg.sender == appContract, "Caller is not authorized");
        Insurance storage insurance = insurances[flightKey];
        uint256 creditAmount = insurance.amount * 3 / 2; // 1.5X
        passengerCredits[insurance.passenger] += creditAmount;
        insurance.credited = true;

        emit PassengerCredited(insurance.passenger, creditAmount);
    }

    function pay(address passenger) external override {
        require(msg.sender == appContract, "Caller is not authorized");
        uint256 amount = passengerCredits[passenger];
        passengerCredits[passenger] = 0;
        payable(passenger).transfer(amount);

        emit PassengerWithdrawn(passenger, amount);
    }

    function getPassengerCredit(address passenger) external view override returns (uint256) {
        return passengerCredits[passenger];
    }

    function getInsurance(bytes32 flightKey) external view override returns (Insurance memory) {
        return insurances[flightKey];
    }


    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns (bytes32){
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
       * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    // Function to get the contract's balance
    function getContractBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether
    receive() external payable override {
        totalReceivedEther += msg.value; // Track total received Ether
        emit ReceivedEther(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable override {
        totalReceivedEther += msg.value; // Track total received Ether
        emit ReceivedEther(msg.sender, msg.value, address(this).balance);
    }

    // Event to log received Ether
    event ReceivedEther(address indexed sender, uint256 amount, uint256 newBalance);
}

