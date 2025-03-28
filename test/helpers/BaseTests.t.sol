// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

///@notice Foundry Stuff
import {Test, console} from "forge-std/Test.sol";

///@notice Protocol Scripts
//Import the Scripts that will be used to deploy your protocol contracts E.g:
import { DeployScript } from "script/Deploy.s.sol";
import { HelperConfig } from "script/helpers/HelperConfig.s.sol";

///@notice Protocol Base Contracts
//Import the contracts that will be tested

///@notice Protocol Upgrade Initializers
//If upgradeable, import scripts for deploy/initialization


contract BaseTests is Test {
    ///@notice Instantiate Scripts
    DeployScript public s_deploy;
    HelperConfig public s_helperConfig;
    
    ///@notice Instantiate Protocol Contracts

    ///@notice Instantiate Upgrade Initializers
    //if exists, otherwise delete it

    ///@notice Proxied Interfaces
    //if exists, otherwise delete it

    //Addresses
    address constant s_owner = address(77);
    address constant s_multiSig = address(777);
    address constant s_user02 = address(2);
    address constant s_user03 = address(3);
    address constant s_user04 = address(4);
    address constant s_user05 = address(5);

    //Utils - Fake Addresses
    address uniswapRouter = makeAddr("uniswapRouter");

    function setUp() public virtual {
        ///@notice 1. Deploys DeployInit script
        s_deploy = new DeployScript();

        ///@notice 2. Deploy Base Contracts Using the deploy script and retrieve contracts deployed
        (
            s_helperConfig
            // s_77,
            // s_777,
            // s_7777,
            // s_77777,
        ) = s_deploy.run();
    }

    
}
