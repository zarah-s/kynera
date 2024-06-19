// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC1155, Ownable {
    string storage_uri;

    constructor(
        address initialOwner,
        string memory _uri
    )
        ERC1155(string(abi.encodePacked(_uri, "{id}.json")))
        Ownable(initialOwner)
    {
        storage_uri = _uri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        storage_uri = newuri;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function uri(uint _tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    storage_uri,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(storage_uri, "main.json"));
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}
