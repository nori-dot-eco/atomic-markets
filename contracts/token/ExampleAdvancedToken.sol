pragma solidity ^0.4.24;
import "../eip777/EIP777TokenBase.sol";


/**
  @title ExampleAdvancedToken is an EIP777 token
*/
contract ExampleAdvancedToken is EIP777TokenBase {

  constructor(
    string _name,
    string _symbol,
    uint256 _granularity
  ) EIP777TokenBase(
    _name,
    _symbol,
    _granularity
  ) public {
    /*Delegate constructor*/
  }
}