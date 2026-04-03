// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeConfigFixtures {
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
        chainIds = new uint256[](5);
        expected = new address[](5);
        uint256 index;

        index = _pushMultiSend(chainIds, expected, index, 1, 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
        index = _pushMultiSend(chainIds, expected, index, 324, 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F);
        index = _pushMultiSend(chainIds, expected, index, 232, 0x0408EF011960d02349d50286D20531229BCef773);
        index = _pushMultiSend(chainIds, expected, index, 10143, 0x9641d764fc13c8B624c04430C7356C1C7C8102e2);
        _pushMultiSend(chainIds, expected, index, 98866, 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
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
