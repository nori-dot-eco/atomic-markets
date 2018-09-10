pragma solidity ^0.4.24;

interface IAdvancedERC721 {

  /*** EVENTS ***/
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

  function approveAndCall(address _operator, uint256 _tokenId, bytes _data) external;
}
