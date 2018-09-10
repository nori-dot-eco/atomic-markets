pragma solidity ^0.4.24;

interface IFifoTokenizedNftMarket {
  function getEarliestSale() public view returns (uint, uint); //todo add the rest of the contract interfaces
}