pragma solidity ^0.4.24;
import "../market/PriceBasedTokenizedNftMarket.sol";


contract PriceBasedMarketplace is PriceBasedTokenizedNftMarket {

  constructor(
    address _nftContract,
    address _tokenContract,
    uint256 _ownersCut
  ) PriceBasedTokenizedNftMarket(_nftContract, _tokenContract, _ownersCut) public {
    // Delegate constructor
  }

}