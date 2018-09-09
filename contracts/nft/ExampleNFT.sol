pragma solidity ^0.4.24;
import "../eip721/AdvancedNFTBase.sol";

contract ExampleNFT is AdvancedNFTBase {

  constructor(
    string _name,
    string _symbol,
    address _owner
  ) public AdvancedNFTBase (
    _name,
    _symbol,
    _owner
  ) {
    // Delegate Constructor
  }

}
