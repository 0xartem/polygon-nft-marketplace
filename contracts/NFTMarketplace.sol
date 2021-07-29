// contracts/Marketplace.sol
// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address owner;
    address seller;
    uint256 price;
    bool sold;
  }

interface IMarketplace {

  function listNFTItem(address nftContract, uint256 tokenId, uint256 price) external payable;
  function buyNFTItem(uint256 itemId) external payable;
  function getMarketItems() external view returns (MarketItem[] memory items);
  function getMyNFTs() external view returns (MarketItem[] memory myNFTs);
  function getMyListedItems() external view returns (MarketItem[] memory myListedItems);
}

contract NFTMarketplace is IMarketplace, ReentrancyGuard {

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

  event MarketItemSold(
    uint256 indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address owner,
    address seller,
    uint256 price
  );

  constructor() payable {
    owner = payable(msg.sender);
  }

  modifier contractNonZero(address nftContract) {
    require(nftContract != address(0), "contractNonZero: NFT Contract cant be zero");
    _;
  }

  function listNFTItem(address nftContract, uint256 tokenId, uint256 price)
    external
    override
    payable
    nonReentrant
    contractNonZero(nftContract) {
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

  function buyNFTItem(uint256 itemId) external override payable nonReentrant {
    MarketItem storage marketItem = marketItems[itemId];
    require(marketItem.nftContract != address(0), "buyNFTItem: NFT Contract address is zero, item doesnt exist");
    require(msg.value == marketItem.price, "buyNFTItem: Price must be equal to the one set by the seller");

    (bool sent, ) = marketItem.seller.call{value: marketItem.price}("");
    require(sent, "buyNFTItem: Paymebnt ether tranfer failed");
    IERC721(marketItem.nftContract).transferFrom(marketItem.seller, msg.sender, marketItem.tokenId);
    marketItem.owner = msg.sender;
    marketItem.sold = true;
    itemsSold.increment();

    (sent, ) = owner.call{value: listingPrice}("");
    require(sent, "buyNFTItem: Listting fee ether tranfer failed");

    emit MarketItemSold(itemId, marketItem.nftContract, marketItem.tokenId, marketItem.owner, marketItem.seller, marketItem.price);
  }

  function getMarketItems() external view override returns (MarketItem[] memory items) {
    uint itemsCount = itemIds.current();
    uint unsoldItems = itemsCount - itemsSold.current();
    
    return filterMarketItemsByOwner(address(0), unsoldItems);
  }

  function getMyNFTs() external view override returns (MarketItem[] memory myNFTs) {
    uint nftsCount = 0;
    uint itemsCount = itemIds.current();
    for (uint i = 0; i < itemsCount; i++) {
      if (marketItems[i].owner == msg.sender) {
        nftsCount++;
      }
    }

    return filterMarketItemsByOwner(msg.sender, nftsCount);
  }

  function getMyListedItems() external view override returns (MarketItem[] memory myListedItems) {
    uint myListedItemsCount = 0;
    uint itemsCount = itemIds.current();
    for (uint i = 0; i < itemsCount; i++) {
      if (marketItems[i].seller == msg.sender) {
        myListedItemsCount++;
      }
    }

    return filterMarketItemsBySeller(msg.sender, myListedItemsCount);
  }

  function filterMarketItemsByOwner(address filterOwner, uint itemsCount) internal view returns (MarketItem[] memory items) {
    uint itemsIdx = 0;
    items = new MarketItem[](itemsCount);
    for (uint i = 0; i < itemIds.current(); i++) {
      MarketItem storage current = marketItems[i];
      if (current.owner == filterOwner) {
        items[itemsIdx] = current;
        itemsIdx++;
      }
    }
  }

  function filterMarketItemsBySeller(address filterSeller, uint itemsCount) internal view returns (MarketItem[] memory items) {
    uint itemsIdx = 0;
    items = new MarketItem[](itemsCount);
    for (uint i = 0; i < itemIds.current(); i++) {
      MarketItem storage current = marketItems[i];
      if (current.seller == filterSeller) {
        items[itemsIdx] = current;
        itemsIdx++;
      }
    }
  }

}