//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

///@notice Foundry Stuff
import { console } from "forge-std/console.sol";

///@notice Scripts
import { InteractionsScript } from "script/Interactions.s.sol";

import { SafeUtils } from "src/SafeUtils.sol";
import { Enum } from "@safe/contracts/interfaces/ISafe.sol";

/**
    *@notice Environment for Forked Tests
    *@dev it inherits the BaseTests so you don't need to declare all it again
    *@notice overrides the setUp function
*/
contract ForkedHelper is Test {

    ///@notice recover the RPC_URLs from the .env file
    string SEP_RPC_URL = vm.envString("SEPOLIA_RPC_URL");

    ///@notice variable store each forked chain
    uint256 sepolia;

    ///@notice script to test
    InteractionsScript public s_interaction;

    ///@notice multi sig address. Update it for you address on the .env file
    address multiSig = vm.envAddress("MULTISIG_ADDRESS");
    address signer;
    uint256 userPrivateKey;
    address signer2 = vm.envAddress("SIGNER2");
    address receiver = vm.envAddress("RECEIVER");

    ///@notice Mock Signer

    function setUp() public {
        ///@notice Create Forked Environment
        sepolia = vm.createFork(SEP_RPC_URL);
        
        ///@notice to select the fork we will use. You can change between them on tests
        vm.selectFork(sepolia);

        ///@notice deploys the Scripts
        s_interaction = new InteractionsScript();

        (signer, userPrivateKey) = makeAddrAndKey("test");
    }

    function payloadConstructor() public view returns(SafeUtils.TransactionPayload memory payload_){
        payload_ = SafeUtils.TransactionPayload({
            to: receiver,
            value: 0.01 ether,
            data: "",
            operation: Enum.Operation.Call ,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: 0x0000000000000000000000000000000000000000,
            refundReceiver: 0x0000000000000000000000000000000000000000,
            _nonce: 2
        });
    }
}