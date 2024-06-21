// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Core {
    address public contractOwner;                                      // Account used to deploy contract
    bool private operational = true;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier requireContractOwner(){
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsOperational(){
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool){
        return operational;  // *** done *** Modify to call data contract's status
    }

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }
}


