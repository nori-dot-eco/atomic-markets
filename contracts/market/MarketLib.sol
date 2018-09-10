pragma solidity ^0.4.18;


library MarketLib {
  // Represents a commodity for sale
  struct Sale {
    //The ID of the NFT as exists in the NFT contract
    uint256 nftId;
    // Current owner of sale
    address seller;
    //Commodity value
    uint256 value;
    // Time when sale started
    // NOTE: 0 if this sale has been concluded
    uint64 startedAt;
  }
}
