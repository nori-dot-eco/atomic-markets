pragma solidity ^0.4.24;
import "../market/FifoTokenizedNftMarket.sol";


contract FifoMarketplace is FifoTokenizedNftMarket {

  constructor(
    address _nftContract,
    address _tokenContract,
    uint256 _ownersCut
  ) FifoTokenizedNftMarket(_nftContract, _tokenContract, _ownersCut) public {
    // Delegate constructor
  }

}