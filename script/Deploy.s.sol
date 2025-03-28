//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///@notice Foundry Stuff
import { Script, console } from "forge-std/Script.sol";

///@notice Scripts Helpers
import { HelperConfig } from "script/helpers/HelperConfig.s.sol";

///@notice Contracts to be deployed

/**
    *@title Core Deploy Script
    *@notice Deployer contract for the protocol core
*/
contract DeployScript is Script {

    /**
        *@dev This function is required in Scripts
        *@notice You can change this simple struct to add params for example the deployment on test files and cli
        *@notice By doing that, you will be changing the function signature.
        *@notice So, you will need to update the signature to call on the CLI
    */
    function run() external returns(HelperConfig helperConfig_){
        
        ///@notice foundry tool to deploy the contract
        vm.startBroadcast();
        
        helperConfig_ = new HelperConfig();

        vm.stopBroadcast();

    }
}