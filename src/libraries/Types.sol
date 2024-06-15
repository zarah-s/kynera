// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

library Types {
    struct Collection {
        string name;
        address contract_address;
        uint256 id;
    }
    struct Minted {
        string collection_name;
        uint256 collection_id;
        uint256[] tokens;
    }
}
