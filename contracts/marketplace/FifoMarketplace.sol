pragma solidity ^0.4.24;
import "../market/FifoTokenizedNftMarket.sol";


contract FifoMarketplace is FifoTokenizedNftMarket {

  constructor(
    address _nftContract,
    address _tokenContract,
    address _owner
  ) FifoTokenizedNftMarket(_nftContract, _tokenContract, _owner) public {
    // Delegate constructor
  }

}