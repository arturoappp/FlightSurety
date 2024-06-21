var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try
        {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
        }
        catch(e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try
        {
            await config.flightSuretyData.setOperatingStatus(false);
        }
        catch(e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try
        {
            await config.flightSuretyApp.setTestingMode(true);
        }
        catch(e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true);

    });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        // ARRANGE
        let newAirline = accounts[2];

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        }
        catch(e) {

        }
        let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);

        // ASSERT
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });

    it('(airline) can register an Airline using registerAirline() if it is funded', async () => {

        // ARRANGE
        let newAirline = accounts[2];
        await config.flightSuretyApp.fundAirline({from: config.firstAirline, value: web3.utils.toWei('10', 'ether')});

        // ACT
        try {
            await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        }
        catch(e) {
            console.log(e.message);
        }
        let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);

        // ASSERT
        assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

    });

    it('(multiparty) requires multiparty consensus for registering fifth and subsequent airlines', async () => {

        // ARRANGE
        let secondAirline = accounts[2];
        let thirdAirline = accounts[3];
        let fourthAirline = accounts[4];
        let fifthAirline = accounts[5];

        // Fund and register first four airlines
        await config.flightSuretyApp.fundAirline({from: config.firstAirline, value: web3.utils.toWei('10', 'ether')});
        await config.flightSuretyApp.registerAirline(secondAirline, {from: config.firstAirline});
        await config.flightSuretyApp.fundAirline({from: secondAirline, value: web3.utils.toWei('10', 'ether')});
        await config.flightSuretyApp.registerAirline(thirdAirline, {from: secondAirline});
        await config.flightSuretyApp.fundAirline({from: thirdAirline, value: web3.utils.toWei('10', 'ether')});
        await config.flightSuretyApp.registerAirline(fourthAirline, {from: thirdAirline});
        await config.flightSuretyApp.fundAirline({from: fourthAirline, value: web3.utils.toWei('10', 'ether')});

        // Register fifth airline with multiparty consensus
        await config.flightSuretyApp.registerAirline(fifthAirline, {from: fourthAirline});
        await config.flightSuretyApp.voteToRegisterAirline(fifthAirline, {from: firstAirline});
        await config.flightSuretyApp.voteToRegisterAirline(fifthAirline, {from: secondAirline});

        let result = await config.flightSuretyData.isAirlineRegistered.call(fifthAirline);

        // ASSERT
        assert.equal(result, true, "Fifth airline should be registered with multiparty consensus");

    });

    it('(airline) cannot participate in contract until it submits funding of 10 ether', async () => {

        // ARRANGE
        let newAirline = accounts[6];

        // ACT
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        let isRegistered = await config.flightSuretyData.isAirlineRegistered.call(newAirline);
        let isFunded = await config.flightSuretyData.isFunded.call(newAirline);

        // ASSERT
        assert.equal(isRegistered, true, "Airline should be registered");
        assert.equal(isFunded, false, "Airline should not be able to participate in contract until it submits funding of 10 ether");

    });

    it('(passenger) can purchase flight insurance for no more than 1 ether', async () => {

        // ARRANGE
        let passenger = accounts[7];
        let flight = 'ND1309';
        let timestamp = Math.floor(Date.now() / 1000);
        let flightKey = web3.utils.soliditySha3(config.firstAirline, flight, timestamp);

        await config.flightSuretyApp.registerFlight(config.firstAirline, flight, timestamp);

        // ACT
        try {
            await config.flightSuretyApp.buyInsurance(flightKey, {from: passenger, value: web3.utils.toWei('1', 'ether')});
        } catch(e) {
            console.log(e.message);
        }

        let insurance = await config.flightSuretyData.getInsurance.call(flightKey);
        let passengerCredit = await config.flightSuretyData.getPassengerCredit.call(passenger);

        // ASSERT
        assert.equal(insurance.passenger, passenger, "Passenger should be able to purchase flight insurance");
        assert.equal(insurance.amount, web3.utils.toWei('1', 'ether'), "Insurance amount should be 1 ether or less");
        assert.equal(passengerCredit, 0, "Passenger credit should be zero initially");

    });

    it('(passenger) receives credit of 1.5X the amount they paid if flight is delayed due to airline fault', async () => {

        // ARRANGE
        let passenger = accounts[7];
        let flight = 'ND1309';
        let timestamp = Math.floor(Date.now() / 1000);
        let flightKey = web3.utils.soliditySha3(config.firstAirline, flight, timestamp);

        await config.flightSuretyApp.registerFlight(config.firstAirline, flight, timestamp);
        await config.flightSuretyApp.buyInsurance(flightKey, {from: passenger, value: web3.utils.toWei('1', 'ether')});

        // Simulate flight delay due to airline fault
        await config.flightSuretyApp.processFlightStatus(config.firstAirline, flight, timestamp, 20);

        let insurance = await config.flightSuretyData.getInsurance.call(flightKey);
        let passengerCredit = await config.flightSuretyData.getPassengerCredit.call(passenger);

        // ASSERT
        assert.equal(insurance.credited, true, "Insurance should be credited");
        assert.equal(passengerCredit, web3.utils.toWei('1.5', 'ether'), "Passenger should receive credit of 1.5X the amount they paid");

    });

    it('(passenger) can withdraw any funds owed to them as a result of receiving credit for insurance payout', async () => {

        // ARRANGE
        let passenger = accounts[7];
        let initialBalance = new BigNumber(await web3.eth.getBalance(passenger));

        // ACT
        await config.flightSuretyApp.pay({from: passenger});
        let finalBalance = new BigNumber(await web3.eth.getBalance(passenger));
        let passengerCredit = await config.flightSuretyData.getPassengerCredit.call(passenger);

        // ASSERT
        assert(finalBalance.isGreaterThan(initialBalance), "Passenger should be able to withdraw funds owed to them");
        assert.equal(passengerCredit, 0, "Passenger credit should be zero after withdrawal");

    });

});
