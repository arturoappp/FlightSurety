// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./FlightSuretyData.sol";
import "./base/Core.sol";

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp is Core {

    FlightSuretyData flightSuretyData;

    // Oracle related variables
    uint8 private nonce = 0;
    uint256 public constant REGISTRATION_FEE = 1 ether;
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    mapping(address => Oracle) private oracles;

    struct ResponseInfo {
        address requester;
        bool isOpen;
        mapping(uint8 => address[]) responses;
    }

    mapping(bytes32 => ResponseInfo) private oracleResponses;

    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);
    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

    event FlightRegistered(address airline, string flight, uint256 timestamp);

    constructor(address payable _dataContract) {
        flightSuretyData = FlightSuretyData(_dataContract);
    }

    modifier onlyFundedAirline() {
        require(flightSuretyData.isFunded(msg.sender), "Airline needs to be funded with 10 ether.");
        _;
    }

    function registerAirline(address _newAirline) external onlyFundedAirline returns (bool) {
        require(_newAirline != address(0), "Invalid airline address.");
        require(!flightSuretyData.isAirlineRegistered(_newAirline), "Airline is already registered.");

        if (flightSuretyData.getNumAirlines() < 4) {
            flightSuretyData.registerAirline(_newAirline);
        } else {
            flightSuretyData.voteToRegisterAirline(_newAirline, msg.sender);
            if (flightSuretyData.getAirlineVotes(_newAirline) >= (flightSuretyData.getNumAirlines() + 1) / 2) {  // 50% of registered airlines
                flightSuretyData.registerAirline(_newAirline);
            }
        }

        return true;
    }

    function fundAirline() external payable {
        require(msg.value == 10 ether, "Funding requires 10 ether.");
        flightSuretyData.fundAirline{value: msg.value}(msg.sender);
    }

    function isFunded(address _airline) external view returns (bool) {
        return flightSuretyData.isFunded(_airline);
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(address airline, string memory flight, uint256 timestamp) external onlyFundedAirline {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        require(!flights[flightKey].isRegistered, "Flight is already registered.");

        flights[flightKey] = Flight({
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: timestamp,
            airline: airline
        });

        emit FlightRegistered(airline, flight, timestamp);
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Oracle Management Functions

    function registerOracle() external payable {
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() view external returns (uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
        return oracles[msg.sender].indexes;
    }

    function submitOracleResponse(
        uint8 index,
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            oracles[msg.sender].indexes[0] == index ||
            oracles[msg.sender].indexes[1] == index ||
            oracles[msg.sender].indexes[2] == index,
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function generateIndexes(address account) internal returns (uint8[3] memory) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        flights[flightKey].statusCode = statusCode;

        if (statusCode == 20) { // Late Airline
            flightSuretyData.creditInsurees(flightKey);
        }

    }
// endregion
}