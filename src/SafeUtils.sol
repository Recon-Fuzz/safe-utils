// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { ISafe } from "@safe/contracts/interfaces/ISafe.sol";
import { Enum } from "@safe/contracts/libraries/Enum.sol";
import { HTTP, StringMap } from "@http/src/HTTP.sol";

library SafeUtils {

    /*///////////////////////////////////
              Type declarations
    ///////////////////////////////////*/
    using HTTP for HTTP.Request;
    using StringMap for StringMap.StringToStringMap;

    /*///////////////////////////////////
              State variables
    ///////////////////////////////////*/
    /**
     * @notice Data Structure to build transaction hash to be signed by owners.
     * to: Destination address.
     * value: Ether value.
     * data: Data payload.
     * operation: Operation type.
     * safeTxGas: Gas that should be used for the safe transaction.
     * baseGas: Gas costs for data used to trigger the safe transaction.
     * gasPrice: Maximum gas price that should be used for this transaction.
     * gasToken: Token address (or 0 if ETH) that is used for the payment.
     * refundReceiver: Address of receiver of gas payment (or 0 if tx.origin).
     * _nonce: Transaction nonce.
     */
    struct TransactionPayload{
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address refundReceiver;
        uint256 _nonce;
    }

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/

    /*///////////////////////////////////
                  internal
    ///////////////////////////////////*/
    /**
        *@notice function to propose transaction through Safe{Core} SDK
        *@param _builder the struct that store requests
        *@return answer_ request's received answer
    */
    function _proposeTransaction(
        HTTP.Builder storage _builder
    ) external returns(HTTP.Response memory answer_){

        HTTP.Request storage req = HTTP.build(_builder);

        HTTP.withUrl(req, req.url);
        HTTP.withMethod(req, HTTP.Method.POST);
        HTTP.withBody(req, req.body);

        console.log("Sending HTTP request");
        answer_ = HTTP.request(req);
    }

    /*///////////////////////////////////
                View & Pure
    ///////////////////////////////////*/
    /**
        *@notice Function to interact with Safe to get the transaction hash
        *@param _safe the wallet's address
        *@param _payload the payload to generate the message
    */
    function _getTransactionHash(ISafe _safe, TransactionPayload memory _payload) internal view returns(bytes32 txHash_){
        console.log("Initiate external call to generate the tx hash");
        txHash_ = _safe.getTransactionHash(
                _payload.to,
                _payload.value,
                _payload.data,
                _payload.operation,
                _payload.safeTxGas,
                _payload.baseGas,
                _payload.gasPrice,
                _payload.gasToken,
                _payload.refundReceiver,
                _payload._nonce
        );
    }

    /**
        *@notice Function to sign the obtained transaction hash using Forge::Vm.sol
        *@dev EIP- compatible
    */
    function _signTransaction(ISafe _safe, TransactionPayload memory _txPayload) internal view returns(bytes memory signedMessage_){
        console.log("Generating the transaction hash:");
        bytes32 dataHash = _getTransactionHash(_safe, _txPayload);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(dataHash);

        signedMessage_ = abi.encodePacked(r, s, v);
    }

}
