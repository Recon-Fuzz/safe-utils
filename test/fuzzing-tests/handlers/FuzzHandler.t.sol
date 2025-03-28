//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//Foundry Stuff
import { Test } from "forge-std/Test.sol";

///@notice Scripts
import { DeployScript } from "script/Deploy.s.sol";
import { HelperConfig } from "script/helpers/HelperConfig.s.sol";

///@notice Protocol Contracts

///@notice Protocol Interfaces

/**
    *@title Fuzz Handler
    *@notice Contract Used on Stateful Fuzzing to direct calls in a more efficient way
*/
contract FuzzHandler is Test {
    ///@notice DeployScript Instance
    DeployScript s_deploy;
    HelperConfig s_helperConfig;

    ///@notice Contract that will be deployed

    function setUp() external {
        s_deploy = new DeployScript();

        (s_helperConfig /* contracts deployed using the script */) = s_deploy.run();
    }

    //Test something
}