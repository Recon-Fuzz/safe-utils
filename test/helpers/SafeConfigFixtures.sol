// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeConfigFixtures {
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V130_ZKSYNC = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
    address constant MULTI_SEND_CALL_ONLY_ADDRESS_V141_ZKSYNC = 0x0408EF011960d02349d50286D20531229BCef773;

    function officialChains() internal pure returns (uint256[] memory chainIds, string[] memory shortNames) {
        chainIds = new uint256[](39);
        shortNames = new string[](39);
        uint256 index;

        index = _pushOfficial(chainIds, shortNames, index, 1, "eth");
        index = _pushOfficial(chainIds, shortNames, index, 10, "oeth");
        index = _pushOfficial(chainIds, shortNames, index, 50, "xdc");
        index = _pushOfficial(chainIds, shortNames, index, 56, "bnb");
        index = _pushOfficial(chainIds, shortNames, index, 100, "gno");
        index = _pushOfficial(chainIds, shortNames, index, 130, "unichain");
        index = _pushOfficial(chainIds, shortNames, index, 137, "pol");
        index = _pushOfficial(chainIds, shortNames, index, 143, "monad");
        index = _pushOfficial(chainIds, shortNames, index, 146, "sonic");
        index = _pushOfficial(chainIds, shortNames, index, 196, "okb");
        index = _pushOfficial(chainIds, shortNames, index, 204, "opbnb");
        index = _pushOfficial(chainIds, shortNames, index, 232, "lens");
        index = _pushOfficial(chainIds, shortNames, index, 324, "zksync");
        index = _pushOfficial(chainIds, shortNames, index, 480, "wc");
        index = _pushOfficial(chainIds, shortNames, index, 988, "stable");
        index = _pushOfficial(chainIds, shortNames, index, 999, "hyper");
        index = _pushOfficial(chainIds, shortNames, index, 1101, "zkevm");
        index = _pushOfficial(chainIds, shortNames, index, 3338, "peaq");
        index = _pushOfficial(chainIds, shortNames, index, 3637, "btc");
        index = _pushOfficial(chainIds, shortNames, index, 5000, "mantle");
        index = _pushOfficial(chainIds, shortNames, index, 8453, "base");
        index = _pushOfficial(chainIds, shortNames, index, 9745, "plasma");
        index = _pushOfficial(chainIds, shortNames, index, 10143, "monad-testnet");
        index = _pushOfficial(chainIds, shortNames, index, 10200, "chi");
        index = _pushOfficial(chainIds, shortNames, index, 16661, "0g");
        index = _pushOfficial(chainIds, shortNames, index, 42161, "arb1");
        index = _pushOfficial(chainIds, shortNames, index, 42220, "celo");
        index = _pushOfficial(chainIds, shortNames, index, 43111, "hemi");
        index = _pushOfficial(chainIds, shortNames, index, 43114, "avax");
        index = _pushOfficial(chainIds, shortNames, index, 57073, "ink");
        index = _pushOfficial(chainIds, shortNames, index, 59144, "linea");
        index = _pushOfficial(chainIds, shortNames, index, 80069, "bep");
        index = _pushOfficial(chainIds, shortNames, index, 80094, "berachain");
        index = _pushOfficial(chainIds, shortNames, index, 81224, "codex");
        index = _pushOfficial(chainIds, shortNames, index, 84532, "basesep");
        index = _pushOfficial(chainIds, shortNames, index, 534352, "scr");
        index = _pushOfficial(chainIds, shortNames, index, 747474, "katana");
        index = _pushOfficial(chainIds, shortNames, index, 11155111, "sep");
        _pushOfficial(chainIds, shortNames, index, 1313161554, "aurora");
    }

    function multiSendChains() internal pure returns (uint256[] memory chainIds, address[] memory expected) {
        chainIds = new uint256[](40);
        expected = new address[](40);
        uint256 index;

        index = _pushMultiSend(chainIds, expected, index, 1, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 10, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 50, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 56, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 100, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 130, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 137, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 143, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 146, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 196, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 204, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 232, MULTI_SEND_CALL_ONLY_ADDRESS_V141_ZKSYNC);
        index = _pushMultiSend(chainIds, expected, index, 324, MULTI_SEND_CALL_ONLY_ADDRESS_V130_ZKSYNC);
        index = _pushMultiSend(chainIds, expected, index, 480, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 988, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 999, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 1101, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 3338, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 3637, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 5000, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 8453, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 9745, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 10143, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 10200, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 16661, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 42161, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 42220, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 43111, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 43114, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 57073, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 59144, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 80069, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 80094, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 81224, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 84532, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 534352, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 747474, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 11155111, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        index = _pushMultiSend(chainIds, expected, index, 1313161554, MULTI_SEND_CALL_ONLY_ADDRESS_V130_CANONICAL);
        _pushMultiSend(chainIds, expected, index, 98866, MULTI_SEND_CALL_ONLY_ADDRESS_V141_CANONICAL);
    }

    function _pushOfficial(
        uint256[] memory chainIds,
        string[] memory shortNames,
        uint256 index,
        uint256 chainId,
        string memory shortName
    ) private pure returns (uint256) {
        chainIds[index] = chainId;
        shortNames[index] = shortName;
        return index + 1;
    }

    function _pushMultiSend(
        uint256[] memory chainIds,
        address[] memory expected,
        uint256 index,
        uint256 chainId,
        address multiSendCallOnly
    ) private pure returns (uint256) {
        chainIds[index] = chainId;
        expected[index] = multiSendCallOnly;
        return index + 1;
    }
}
