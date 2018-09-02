pragma solidity ^0.4.24;
import "../market/SelectableTokenizedNftMarket.sol";


contract SelectableCrcMarketplace is SelectableTokenizedNftMarket {

  constructor(address[] _marketItems, address _owner) SelectableTokenizedNftMarket(_marketItems, _owner) public {
    // Delegate constructor
  }

}