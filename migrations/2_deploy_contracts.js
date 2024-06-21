const FlightSuretyData = artifacts.require("FlightSuretyDataImpl");
const FlightSuretyApp = artifacts.require("FlightSuretyApp");

module.exports = async function(deployer) {
    await deployer.deploy(FlightSuretyData);
    const flightSuretyData = await FlightSuretyData.deployed();

    await deployer.deploy(FlightSuretyApp, flightSuretyData.address);
    const flightSuretyApp = await FlightSuretyApp.deployed();

    // Authorize the FlightSuretyApp contract to call the FlightSuretyData contract
    await flightSuretyData.authorizeCaller(flightSuretyApp.address);
};