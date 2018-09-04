pragma solidity ^0.4.24;
import "../market/FifoTokenizedNftMarket.sol";


contract FifoMarketplace is FifoTokenizedNftMarket {

  constructor(address[] _marketItems, address _owner) FifoTokenizedNftMarket(_marketItems, _owner) public {
    // Delegate constructor
  }

}