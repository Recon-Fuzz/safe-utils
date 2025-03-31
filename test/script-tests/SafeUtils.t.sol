///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SafeUtils } from "src/SafeUtils.sol";

import { ForkedHelper } from "test/helpers/ForkedHelper.t.sol";

contract SafeUtilsTest is ForkedHelper {

    ///@notice function to test if Lib is successful generating the tx hash through the multi-sig
    function test_getTransactionHashFromScriptUsingSafeUtils() public {
        SafeUtils.TransactionPayload memory payload = payloadConstructor();

        s_interaction.getTransactionHash(multiSig, payload);
    }


    function test_signTransactionWorksAfterGeneratingTheTxHash() public {
        SafeUtils.TransactionPayload memory payload = payloadConstructor();

        s_interaction.signTransaction(multiSig, payload, userPrivateKey);
    }
}