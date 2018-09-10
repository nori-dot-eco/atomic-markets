pragma solidity ^0.4.24;
import "../market/FifoTokenizedNftMarket.sol";


contract FifoMarketplace is FifoTokenizedNftMarket {

  constructor(
    address _nftContract,
    address _tokenContract
  ) FifoTokenizedNftMarket(_nftContract, _tokenContract) public {
    // Delegate constructor
  }

}