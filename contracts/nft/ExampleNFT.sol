pragma solidity ^0.4.24;
import "../eip721/AdvancedERC721Base.sol";

contract ExampleNFT is AdvancedERC721Base {

  constructor(
    string _name,
    string _symbol
  ) public AdvancedERC721Base (
    _name,
    _symbol
  ) {
    // Delegate Constructor
  }

}
