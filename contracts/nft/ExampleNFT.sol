pragma solidity ^0.4.24;
import "../eip721/MintableCommodity.sol";

contract ExampleNFT is MintableCommodity {

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
