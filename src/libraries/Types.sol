// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

library Types {
    enum Slot {
        HEAD,
        GLASSES
    }
    struct Collection {
        string name;
        address contract_address;
        uint256 id;
    }
    struct Minted {
        uint256 collection_id;
        Slot slot;
        uint256[] tokens;
    }
}
