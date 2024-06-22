// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./NFT.sol";
import "./libraries/Types.sol";
import "./libraries/Errors.sol";
import "./libraries/AppStorage.sol";

contract Kynera {
    AppStorage.Layout internal layout;

    constructor() {
        layout.owner = msg.sender;
    }

    modifier OnlyOwner() {
        if (msg.sender != layout.owner) {
            revert Errors.UNAUTHORIZED();
        }
        _;
    }

    function setTokenSupply(
        uint collectionId,
        Types.Slot slot,
        uint tokenId,
        uint supply
    ) external OnlyOwner {
        layout.totalSupply[collectionId][uint(slot)][tokenId] = supply;
    }

    function getTokenTotalSupply(
        uint collectionId,
        Types.Slot slot,
        uint tokenId
    ) external view returns (uint) {
        return layout.totalSupply[collectionId][uint(slot)][tokenId];
    }

    function setAccessoryURI(
        uint collectionId,
        Types.Slot slot,
        string calldata uri
    ) external {
        AppStorage.setAccessoryURI(collectionId, slot, uri);
    }

    function createCollection(string calldata _name) external OnlyOwner {
        if (layout.collection_by_name[_name].id != 0) {
            revert Errors.COLLECTION_ALREADY_EXIST();
        }

        layout.collection_count += 1;
        Types.Collection memory _new_collection = Types.Collection({
            name: _name,
            id: layout.collection_count
        });

        layout.collection_by_id[layout.collection_count] = _new_collection;
        layout.collection_by_name[_name] = _new_collection;
    }

    function mint(
        uint256 collectionId,
        address account,
        uint256 tokenId,
        Types.Slot slot,
        uint256 amount,
        bytes memory data
    ) external OnlyOwner {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];

        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        uint tokenTotalSupply = layout.totalSupply[collectionId][uint(slot)][
            tokenId
        ];
        if (amount > tokenTotalSupply) {
            revert Errors.INSUFFICIENT_SUPPLY();
        }
        Types.Token[] storage _minteds = layout.minted[account][collectionId][
            uint(slot)
        ];
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        Types.Token memory tokenData = Types.Token({
            uri: NFT(_accessory).uri(tokenId),
            token_id: tokenId,
            slot: slot
        });
        _minteds.push(tokenData);
        layout.totalSupply[collectionId][uint(slot)][tokenId] -= amount;

        NFT(_accessory).mint(account, tokenId, amount, data);
    }

    function mintBatch(
        uint256 collectionId,
        address to,
        uint256[] memory ids,
        Types.Slot slot,
        uint256[] memory amounts,
        bytes memory data
    ) external OnlyOwner {
        {
            if (ids.length != amounts.length) {
                revert Errors.ERC1155InvalidArrayLength();
            }
        }

        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        {
            Types.Token[] storage _minteds = layout.minted[to][collectionId][
                uint(slot)
            ];
            for (uint256 i; i < ids.length; i++) {
                uint tokenTotalSupply = layout.totalSupply[collectionId][
                    uint(slot)
                ][ids[i]];
                if (amounts[i] > tokenTotalSupply) {
                    revert Errors.INSUFFICIENT_SUPPLY();
                }

                Types.Token memory tokenData = Types.Token({
                    uri: NFT(_accessory).uri(ids[i]),
                    slot: slot,
                    token_id: ids[i]
                });
                _minteds.push(tokenData);
                layout.totalSupply[collectionId][uint(slot)][ids[i]] -= amounts[
                    i
                ];
            }
        }

        NFT(_accessory).mintBatch(to, ids, amounts, data);
    }

    function getAllCollections()
        external
        view
        returns (Types.Collection[] memory)
    {
        if (layout.collection_count == 0) {
            return new Types.Collection[](0);
        } else {
            Types.Collection[] memory collections = new Types.Collection[](
                layout.collection_count
            );
            uint256 _insertIndex;
            for (uint256 i = 1; i < layout.collection_count + 1; i++) {
                collections[_insertIndex] = layout.collection_by_id[i];
                _insertIndex += 1;
            }

            return collections;
        }
    }

    function getUserMintedTokens(
        address user,
        uint collectionId
    ) external view returns (Types.Minted[] memory) {
        Types.Minted[] memory _minteds = new Types.Minted[](
            AppStorage.SLOT_COUNT
        );
        uint256 _insertIndex;
        for (uint i; i < AppStorage.SLOT_COUNT; i++) {
            Types.Token[] memory _tokens = layout.minted[user][collectionId][i];

            _minteds[_insertIndex] = Types.Minted({
                collection_id: collectionId,
                slot: Types.Slot(i),
                tokens: _tokens
            });
            _insertIndex += 1;
        }

        return _minteds;
    }

    function balanceOf(
        uint collectionId,
        address account,
        uint256 id,
        Types.Slot slot
    ) external view returns (uint256) {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];

        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }

        return NFT(_accessory).balanceOf(account, id);
    }

    function balanceOfBatch(
        uint collectionId,
        Types.Slot slot,
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        return NFT(_accessory).balanceOfBatch(accounts, ids);
    }

    function setApprovalForAll(
        uint collectionId,
        Types.Slot slot,
        address operator,
        bool approved
    ) external {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        return NFT(_accessory).setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        uint collectionId,
        Types.Slot slot,
        address account,
        address operator
    ) external view returns (bool) {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        return NFT(_accessory).isApprovedForAll(account, operator);
    }

    function safeTransferFrom(
        uint collectionId,
        Types.Slot slot,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        return NFT(_accessory).safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        uint collectionId,
        Types.Slot slot,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external {
        Types.Collection memory _collection = layout.collection_by_id[
            collectionId
        ];
        if (_collection.id == 0) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        address _accessory = layout.accessory[collectionId][slot];
        if (_accessory == address(0)) {
            revert Errors.ACCESSORY_NOT_SET();
        }
        return
            NFT(_accessory).safeBatchTransferFrom(from, to, ids, values, data);
    }
}
