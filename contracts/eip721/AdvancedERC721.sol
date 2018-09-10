pragma solidity ^0.4.24;

interface AdvancedERC721 {

  /*** EVENTS ***/
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

  function approveAndCall(address _operator, uint256 _tokenId, bytes _data) external;
  function clearApprovalAndCall(uint256 _tokenId) external;
}
