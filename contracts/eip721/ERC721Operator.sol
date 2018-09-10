pragma solidity ^0.4.24;

interface ERC721Operator {
  function madeOperatorForNFT(
    address operator,
    address from,
    address to,
    uint tokenId,
    uint256 value,
    bytes userData,
    bytes operatorData
  ) public;

  function revokedOperatorForNFT(
    address operator,
    address from,
    address to,
    uint tokenId,
    uint256 value,
    bytes userData,
    bytes operatorData
  ) public;
}
