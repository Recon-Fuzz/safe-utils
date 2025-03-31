//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///@notice Foundry Stuff
import { Script, console, console2 } from "forge-std/Script.sol";

import { SafeUtils } from "src/SafeUtils.sol";

import { ISafe } from "@safe/contracts/interfaces/ISafe.sol";

/**
    *@title Core Deploy Script
    *@notice Deployer contract for the protocol core
*/
contract InteractionsScript is Script {

    /**
        *@dev This function is required in Scripts
        *@notice You can change this simple struct to add params for example the deployment on test files and cli
        *@notice By doing that, you will be changing the function signature.
        *@notice So, you will need to update the signature to call on the CLI
    */
    function run() external {
        
        ///@notice foundry tool to deploy the contract
        vm.startBroadcast();
        

        vm.stopBroadcast();
    }

    function getTransactionHash(address _safe, SafeUtils.TransactionPayload memory _payload) public returns(bytes32 txHash_){
        console.log("Get transaction Hash");
        txHash_ = SafeUtils._getTransactionHash(ISafe(_safe), _payload);
        console.logBytes32(txHash_);
    }

    function signTransaction(address _safe, SafeUtils.TransactionPayload memory _payload, uint256 _pk) external returns(bytes memory signedMessage_){
        console.log("Start the Signing Process");
        signedMessage_ = SafeUtils._signTransaction(ISafe(_safe), _payload, _pk);
        console.logBytes(signedMessage_);
    }
}