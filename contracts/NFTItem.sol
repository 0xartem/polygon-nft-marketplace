// contracts/NFTItem.sol
// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract NFTItem is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private tokenIds;
  address marketplaceAddress;

  constructor(address _marketplaceAddress)
    ERC721("NFT Marketplace Item", "NMI") {
      marketplaceAddress = _marketplaceAddress;
      console.log("mkp addr: ", marketplaceAddress);
    }

  function createItem(string memory tokenURI) public returns (uint tokenId) {

    tokenId = tokenIds.current();
    _mint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenURI);
    // this.setApprovalForAll(marketplaceAddress, true);
    tokenIds.increment();
    return tokenId;
  }
}