//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///@notice Foundry Stuff
import { console } from "forge-std/console.sol";

///@notice Scripts
import { DeployScript } from "script/Deploy.s.sol";

///@notice Test Helpers
import { BaseTests } from "./BaseTests.t.sol";

///@notice Protocol contracts

/**
    *@notice Environment for Forked Tests
    *@dev it inherits the BaseTests so you don't need to declare all it again
    *@notice overrides the setUp function
*/
contract ForkedHelper is BaseTests {

    ///@notice recover the RPC_URLs from the .env file
    string BASE_SEP_RPC_URL = vm.envString("BASE_SEP_RPC_URL");
    string BASE_RPC_URL = vm.envString("BASE_MAINNET_RPC");
    ///@notice variable store each forked chain
    uint256 baseSepolia;
    uint256 baseMainnet;

    ///@notice Mainnet variables like tokens. They could be store on the HelperConfig as well if you will work with only one ou a few.
    // IERC20 constant USDC_BASE_MAINNET = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    // IERC20 constant WETH_BASE_MAINNET = IERC20(0x4200000000000000000000000000000000000006);

    ///@notice Sometimes is easier to get and valid address on-chain and use their money, like this:
    address constant USDC_HOLDER = 0xD34EA7278e6BD48DefE656bbE263aEf11101469c; //Coinbase7 Wallet

    ///@notice always use CONSTANTS instead of Magic Numbers> Like this ones: 
    uint24 constant USDC_WETH_POOL_FEE = 500; //0.05% - Uniswap Variables
    uint256 constant USDC_INITIAL_BALANCE = 10_000*10**6; // Token Amounts

    function setUp() public override {
        ///@notice Create Forked Environment
        baseSepolia = vm.createFork(BASE_SEP_RPC_URL);
        baseMainnet = vm.createFork(BASE_RPC_URL);
        
        ///@notice to select the fork we will use. You can change between them on tests
        vm.selectFork(baseMainnet);

        ///@notice deploys the Scripts
        s_deploy = new DeployScript();

        ///@notice get the deployed 
        (s_helperConfig) = s_deploy.run();

        ///@notice Use the Coinbase Wallet to distribute some USDC to our wallets
        vm.startPrank(USDC_HOLDER);
        // USDC_BASE_MAINNET.transfer(s_user02, USDC_INITIAL_BALANCE);
        // USDC_BASE_MAINNET.transfer(s_user03, USDC_INITIAL_BALANCE);
        // USDC_BASE_MAINNET.transfer(s_user04, USDC_INITIAL_BALANCE);
        // USDC_BASE_MAINNET.transfer(s_user05, USDC_INITIAL_BALANCE);
        vm.stopPrank();
    }
}