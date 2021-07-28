// contracts/Marketplace.sol
// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IMarketplace {
  function listNFTItem(address nftContract, uint256 tokenId, uint256 price) external payable;
  function buyNFTItem(address nftContract, uint256 tokenId) external payable;
}

contract NFTMarketplace {

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address owner;
    address seller;
    uint256 price;
    bool sold;
  }

  using Counters for Counters.Counter;

  Counters.Counter private itemIds;
  Counters.Counter private itemsSold;
  
  address payable public owner;
  uint256 listingPrice = 0.025 ether;

  mapping(uint256 => MarketItem) marketItems;

  event MarketItemCreated(
    uint256 indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address owner,
    address seller,
    uint256 price,
    bool sold
  );

  constructor() payable {
    owner = payable(msg.sender);
  }

  function listNFTItem(address nftContract, uint256 tokenId, uint256 price) external payable {
    require(nftContract != address(0), "listNFTItem: NFT Contract cant be zero");
    require(price > 0, "listNFTItem: price for NFT must be higher than zero");
    require(msg.value == listingPrice, "listingPrice: price must be equal to the listing price");

    address tokenOwner = address(0);
    address tokenSeller = msg.sender;

    itemIds.increment();
    uint256 itemId = itemIds.current();
    marketItems[itemId] = MarketItem(
      itemId,
      nftContract,
      tokenId,
      tokenOwner,
      tokenSeller,
      price,
      false
    );

    IERC721(nftContract).transferFrom(tokenSeller, address(this), tokenId);

    emit MarketItemCreated(itemId, nftContract, tokenId, tokenOwner, tokenSeller, price, false);
  }

}