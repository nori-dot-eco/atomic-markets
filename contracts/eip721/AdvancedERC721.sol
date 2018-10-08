pragma solidity ^0.4.24;

interface AdvancedERC721 {

  function approveAndCall(address _operator, uint256 _tokenId, bytes _data) external;
  function clearApprovalAndCall(uint256 _tokenId) external;
  function getAllApprovedFor(address _operator) public returns(uint256[]);

}
