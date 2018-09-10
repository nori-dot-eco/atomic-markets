pragma solidity ^0.4.24;


interface ExtendedERC777Token {
  function approveAndCall(address _operator, uint256 _amount, bytes _userData) external returns (bool success);
}

