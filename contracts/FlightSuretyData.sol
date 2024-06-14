// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FlightSuretyData {
    function setIsAuthorizedCaller(address _address, bool isAuthorized) public virtual;

    function createAirline(address airlineAddress, bool isVoter) public virtual;

    function addFunds(uint _funds) public virtual;

    function getAirlinesCount() public view virtual returns (uint);

    function createInsurance(uint _flightId, uint _amountPaid, address _owner) public virtual;

    function getInsurance(uint _id) public view virtual returns (uint id, uint flightId, string memory state, uint amountPaid, address owner);

    function createFlight(string memory _code, uint _departureTimestamp, address _airlineAddress) public virtual;

    function getFlight(uint _id) public view virtual returns (string memory code, uint departureTimestamp, uint8 departureStatusCode, uint updated);

    function getInsurancesByFlight(uint _flightId) public view virtual returns (uint[] memory);

    function creditInsurance(uint _id, uint _amountToCredit) public virtual;

    function getAirline(address _address) public view virtual returns (address, uint, bool);

    function setAirlineIsVoter(address _address, bool isVoter) public virtual;

    function setDepartureStatusCode(uint _flightId, uint8 _statusCode) public virtual;

    function setUnavailableForInsurance(uint flightId) public virtual;

    function getFlightIdByKey(bytes32 key) public view virtual returns (uint);

    function createFlightKey(address _airlineAddress, string memory flightCode, uint timestamp) public virtual returns (bytes32);

    function withdrawCreditedAmount(uint _amountToWithdraw, address _address) public virtual payable;

    function getCreditedAmount(address _address) public view virtual returns (uint);
}