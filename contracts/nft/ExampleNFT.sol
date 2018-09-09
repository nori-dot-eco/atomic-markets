pragma solidity ^0.4.24;
import "../eip721/AdvancedERC721.sol";

contract ExampleNFT is AdvancedERC721 {

  constructor(
    string _name,
    string _symbol,
    address _owner
  ) public AdvancedERC721 (
    _name,
    _symbol,
    _owner
  ) {
    // Delegate Constructor
  }

}
