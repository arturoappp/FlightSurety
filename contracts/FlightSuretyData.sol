// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base/Core.sol";

abstract contract FlightSuretyData is Core {
    uint256 public numAirlines;
    mapping(address => bool) public airlines;
    mapping(address => uint256) public funds;
    mapping(address => address[]) public airlineVotes;

    // Passenger-related mappings
    mapping(bytes32 => Insurance) public insurances;
    mapping(address => uint256) public passengerCredits;

    struct Insurance {
        address passenger;
        uint256 amount;
        bool credited;
    }

    event AirlineRegistered(address airlineAddress);
    event AirlineFunded(address airlineAddress);
    event InsurancePurchased(address passenger, bytes32 flightKey, uint256 amount);
    event PassengerCredited(address passenger, uint256 amount);
    event PassengerWithdrawn(address passenger, uint256 amount);

    constructor() {
        airlines[contractOwner] = true;
        numAirlines = 1;
    }

    function isAirlineRegistered(address _airline) external view virtual returns (bool);
    function registerAirline(address _newAirline) external virtual;
    function voteToRegisterAirline(address _newAirline, address _voter) external virtual;
    function fundAirline(address _airline) external payable virtual;
    function isFunded(address _airline) external view virtual returns (bool);
    function getNumAirlines() external view virtual returns (uint256);
    function getAirlineVotes(address _airline) external view virtual returns (uint256);

    // Passenger-related functions
    function buyInsurance(address passenger, bytes32 flightKey, uint256 amount) external payable virtual;
    function creditInsurees(bytes32 flightKey) external virtual;
    function pay(address passenger) external virtual;
    function getPassengerCredit(address passenger) external view virtual returns (uint256);

    function getInsurance(bytes32 flightKey) external view virtual returns (Insurance memory);

    // Function to get the contract's balance
    function getContractBalance() external view virtual returns (uint256);

    // Fallback function to receive Ether
    receive() external payable virtual;

    fallback() external payable virtual;
}
