// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./NFT.sol";
import "./libraries/Types.sol";
import "./libraries/Errors.sol";

contract FookBear {
    uint constant SLOT_COUNT = 7;
    address owner;
    uint256 collection_count;
    mapping(uint256 => Types.Collection) collection_by_id;
    mapping(string => Types.Collection) collection_by_name;
    mapping(address => mapping(uint256 => mapping(uint => uint256[]))) minted;

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        if (msg.sender != owner) {
            revert Errors.UNAUTHORIZED();
        }
        _;
    }

    function createCollection(
        string calldata _name,
        string calldata uri
    ) external OnlyOwner {
        collection_count += 1;
        address _new_collection_contract = address(new NFT(address(this), uri));
        Types.Collection memory _new_collection = Types.Collection({
            name: _name,
            contract_address: _new_collection_contract,
            id: collection_count
        });

        collection_by_id[collection_count] = _new_collection;
        collection_by_name[_name] = _new_collection;
    }

    function mint(
        uint256 collectionId,
        address account,
        uint256 tokenId,
        Types.Slot slot,
        uint256 amount,
        bytes memory data
    ) external OnlyOwner {
        Types.Collection memory _collection = collection_by_id[collectionId];

        if (_collection.contract_address == address(0)) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        uint256[] storage _minteds = minted[account][collectionId][uint(slot)];
        _minteds.push(tokenId);

        NFT(_collection.contract_address).mint(account, tokenId, amount, data);
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
                revert();
            }
        }

        Types.Collection memory _collection = collection_by_id[collectionId];
        if (_collection.contract_address == address(0)) {
            revert Errors.COLLECTION_DOES_NOT_EXIST();
        }
        {
            uint256[] storage _minteds = minted[to][collectionId][uint(slot)];
            for (uint256 i; i < ids.length; i++) {
                _minteds.push(ids[i]);
            }
        }

        NFT(_collection.contract_address).mintBatch(to, ids, amounts, data);
    }

    function getAllCollections()
        external
        view
        returns (Types.Collection[] memory)
    {
        if (collection_count == 0) {
            return new Types.Collection[](0);
        } else {
            Types.Collection[] memory collections = new Types.Collection[](
                collection_count
            );
            uint256 _insertIndex;
            for (uint256 i = 1; i < collection_count + 1; i++) {
                collections[_insertIndex] = collection_by_id[i];
                _insertIndex += 1;
            }

            return collections;
        }
    }

    function getUserMintedTokens(
        address user,
        uint collectionId
    ) external view returns (Types.Minted[] memory) {
        Types.Minted[] memory _minteds = new Types.Minted[](SLOT_COUNT);
        uint256 _insertIndex;
        for (uint i; i < SLOT_COUNT; i++) {
            uint[] memory _tokens = minted[user][collectionId][i];

            _minteds[_insertIndex] = Types.Minted({
                collection_id: collectionId,
                slot: Types.Slot(i),
                tokens: _tokens
            });
            _insertIndex += 1;
        }

        return _minteds;
    }
}