// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;
import "./Types.sol";
import "./Errors.sol";
import "./Types.sol";
import "../NFT.sol";

library AppStorage {
    uint constant SLOT_COUNT = 7;
    struct Layout {
        address owner;
        uint256 collection_count;
        mapping(uint256 => Types.Collection) collection_by_id;
        mapping(uint => mapping(Types.Slot => address)) accessory;
        mapping(address => mapping(uint256 => mapping(uint => uint256[]))) minted;
    }

    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function setAccessoryURI(
        uint collectionId,
        Types.Slot slot,
        string calldata uri
    ) external {
        Layout storage layout = AppStorage.layoutStorage();
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];

        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            address _new_accessory_contract = address(
                new NFT(address(this), uri)
            );
            layout.accessory[collectionId][slot] = _new_accessory_contract;
        } else {
            NFT(_accessory).setURI(uri);
        }
    }
}
