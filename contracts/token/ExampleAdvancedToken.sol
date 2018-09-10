pragma solidity ^0.4.24;
import "../eip777/ExtendedERC777TokenBase.sol";


/**
  @title ExampleAdvancedToken is an ERC777 token
*/
contract ExampleAdvancedToken is ExtendedERC777TokenBase {

  constructor(
    string _name,
    string _symbol,
    uint256 _granularity
  ) ExtendedERC777TokenBase(
    _name,
    _symbol,
    _granularity
  ) public {
    /*Delegate constructor*/
  }
}