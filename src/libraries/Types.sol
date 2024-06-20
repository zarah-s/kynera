// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

library Types {
    enum Slot {
        HEAD,
        GLASSES
    }

    struct Collection {
        string name;
        uint256 id;
    }
    struct Token {
        string uri;
        uint token_id;
        Types.Slot slot;
    }
    struct Minted {
        uint256 collection_id;
        Slot slot;
        Token[] tokens;
    }
}
