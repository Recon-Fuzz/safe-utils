// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeConfigFixtures {
    function officialChains() internal pure returns (uint256[] memory chainIds, string[] memory shortNames) {
        chainIds = new uint256[](39);
        shortNames = new string[](39);
        uint256 index;

        chainIds[index] = 1;
        shortNames[index++] = "eth";
        chainIds[index] = 10;
        shortNames[index++] = "oeth";
        chainIds[index] = 50;
        shortNames[index++] = "xdc";
        chainIds[index] = 56;
        shortNames[index++] = "bnb";
        chainIds[index] = 100;
        shortNames[index++] = "gno";
        chainIds[index] = 130;
        shortNames[index++] = "unichain";
        chainIds[index] = 137;
        shortNames[index++] = "pol";
        chainIds[index] = 143;
        shortNames[index++] = "monad";
        chainIds[index] = 146;
        shortNames[index++] = "sonic";
        chainIds[index] = 196;
        shortNames[index++] = "okb";
        chainIds[index] = 204;
        shortNames[index++] = "opbnb";
        chainIds[index] = 232;
        shortNames[index++] = "lens";
        chainIds[index] = 324;
        shortNames[index++] = "zksync";
        chainIds[index] = 480;
        shortNames[index++] = "wc";
        chainIds[index] = 988;
        shortNames[index++] = "stable";
        chainIds[index] = 999;
        shortNames[index++] = "hyper";
        chainIds[index] = 1101;
        shortNames[index++] = "zkevm";
        chainIds[index] = 3338;
        shortNames[index++] = "peaq";
        chainIds[index] = 3637;
        shortNames[index++] = "btc";
        chainIds[index] = 5000;
        shortNames[index++] = "mantle";
        chainIds[index] = 8453;
        shortNames[index++] = "base";
        chainIds[index] = 9745;
        shortNames[index++] = "plasma";
        chainIds[index] = 10143;
        shortNames[index++] = "monad-testnet";
        chainIds[index] = 10200;
        shortNames[index++] = "chi";
        chainIds[index] = 16661;
        shortNames[index++] = "0g";
        chainIds[index] = 42161;
        shortNames[index++] = "arb1";
        chainIds[index] = 42220;
        shortNames[index++] = "celo";
        chainIds[index] = 43111;
        shortNames[index++] = "hemi";
        chainIds[index] = 43114;
        shortNames[index++] = "avax";
        chainIds[index] = 57073;
        shortNames[index++] = "ink";
        chainIds[index] = 59144;
        shortNames[index++] = "linea";
        chainIds[index] = 80069;
        shortNames[index++] = "bep";
        chainIds[index] = 80094;
        shortNames[index++] = "berachain";
        chainIds[index] = 81224;
        shortNames[index++] = "codex";
        chainIds[index] = 84532;
        shortNames[index++] = "basesep";
        chainIds[index] = 534352;
        shortNames[index++] = "scr";
        chainIds[index] = 747474;
        shortNames[index++] = "katana";
        chainIds[index] = 11155111;
        shortNames[index++] = "sep";
        chainIds[index] = 1313161554;
        shortNames[index++] = "aurora";
    }

    function multiSendChains() internal pure returns (uint256[] memory chainIds, address[] memory expected) {
        chainIds = new uint256[](5);
        expected = new address[](5);
        uint256 index;

        chainIds[index] = 1;
        expected[index++] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        chainIds[index] = 324;
        expected[index++] = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;
        chainIds[index] = 232;
        expected[index++] = 0x0408EF011960d02349d50286D20531229BCef773;
        chainIds[index] = 10143;
        expected[index++] = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
        chainIds[index] = 98866;
        expected[index++] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    }
}
