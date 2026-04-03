// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeConfigFixtures {
    function officialChains() internal pure returns (uint256[] memory chainIds, string[] memory shortNames) {
        chainIds = new uint256[](39);
        shortNames = new string[](39);

        chainIds[0] = 1;
        shortNames[0] = "eth";
        chainIds[1] = 10;
        shortNames[1] = "oeth";
        chainIds[2] = 50;
        shortNames[2] = "xdc";
        chainIds[3] = 56;
        shortNames[3] = "bnb";
        chainIds[4] = 100;
        shortNames[4] = "gno";
        chainIds[5] = 130;
        shortNames[5] = "unichain";
        chainIds[6] = 137;
        shortNames[6] = "pol";
        chainIds[7] = 143;
        shortNames[7] = "monad";
        chainIds[8] = 146;
        shortNames[8] = "sonic";
        chainIds[9] = 196;
        shortNames[9] = "okb";
        chainIds[10] = 204;
        shortNames[10] = "opbnb";
        chainIds[11] = 232;
        shortNames[11] = "lens";
        chainIds[12] = 324;
        shortNames[12] = "zksync";
        chainIds[13] = 480;
        shortNames[13] = "wc";
        chainIds[14] = 988;
        shortNames[14] = "stable";
        chainIds[15] = 999;
        shortNames[15] = "hyper";
        chainIds[16] = 1101;
        shortNames[16] = "zkevm";
        chainIds[17] = 3338;
        shortNames[17] = "peaq";
        chainIds[18] = 3637;
        shortNames[18] = "btc";
        chainIds[19] = 5000;
        shortNames[19] = "mantle";
        chainIds[20] = 8453;
        shortNames[20] = "base";
        chainIds[21] = 9745;
        shortNames[21] = "plasma";
        chainIds[22] = 10143;
        shortNames[22] = "monad-testnet";
        chainIds[23] = 10200;
        shortNames[23] = "chi";
        chainIds[24] = 16661;
        shortNames[24] = "0g";
        chainIds[25] = 42161;
        shortNames[25] = "arb1";
        chainIds[26] = 42220;
        shortNames[26] = "celo";
        chainIds[27] = 43111;
        shortNames[27] = "hemi";
        chainIds[28] = 43114;
        shortNames[28] = "avax";
        chainIds[29] = 57073;
        shortNames[29] = "ink";
        chainIds[30] = 59144;
        shortNames[30] = "linea";
        chainIds[31] = 80069;
        shortNames[31] = "bep";
        chainIds[32] = 80094;
        shortNames[32] = "berachain";
        chainIds[33] = 81224;
        shortNames[33] = "codex";
        chainIds[34] = 84532;
        shortNames[34] = "basesep";
        chainIds[35] = 534352;
        shortNames[35] = "scr";
        chainIds[36] = 747474;
        shortNames[36] = "katana";
        chainIds[37] = 11155111;
        shortNames[37] = "sep";
        chainIds[38] = 1313161554;
        shortNames[38] = "aurora";
    }

    function multiSendChains() internal pure returns (uint256[] memory chainIds, address[] memory expected) {
        chainIds = new uint256[](5);
        expected = new address[](5);

        chainIds[0] = 1;
        expected[0] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
        chainIds[1] = 324;
        expected[1] = 0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F;
        chainIds[2] = 232;
        expected[2] = 0x0408EF011960d02349d50286D20531229BCef773;
        chainIds[3] = 10143;
        expected[3] = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
        chainIds[4] = 98866;
        expected[4] = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    }
}
