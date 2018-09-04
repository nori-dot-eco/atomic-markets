pragma solidity ^0.4.24;
import "../eip721/BasicCommodity.sol";

contract ExampleNFT is BasicCommodity {

  constructor(
    string _name,
    string _symbol,
    address _owner
  ) public BasicCommodity (
    _name,
    _symbol,
    _owner
  ) {
    // Delegate Constructor
  }

}
