pragma solidity ^0.4.24;
import "../market/PriceBasedTokenizedNftMarket.sol";


contract PriceBasedMarketplace is PriceBasedTokenizedNftMarket {

   constructor(
    address _nftContract,
    address _tokenContract,
    address _owner
  ) PriceBasedTokenizedNftMarket(_nftContract, _tokenContract, _owner) public {
    // Delegate constructor
  }

}