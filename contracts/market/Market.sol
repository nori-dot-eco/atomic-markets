pragma solidity ^0.4.24;
import "../../node_modules/eip820/contracts/ERC820Implementer.sol";
import "../../node_modules/eip820/contracts/ERC820ImplementerInterface.sol";
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Market is Ownable, ERC820Implementer, ERC820ImplementerInterface {
  using SafeMath for uint256;

  bool internal preventTokenReceived = true;
  bool internal preventTokenOperator = true;
  bool internal preventNFTReceived = true;
  bool internal preventNFTOperator = true;
  uint256 public ownersCut;

  constructor(uint256 _ownersCut) public {
    ownersCut = _ownersCut;
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    preventTokenOperator = false;
    setInterfaceImplementation("ERC777TokensOperator", this);
    preventNFTOperator = false;
    setInterfaceImplementation("ERC721Operator", this);
  }

  function canImplementInterfaceForAddress(address, bytes32) public view returns(bytes32) {
    return ERC820_ACCEPT_MAGIC;
  }

  function enableEIP777TokensOperator() public onlyOwner {
    preventTokenOperator = false;
    setInterfaceImplementation("ERC777TokensOperator", this);
  }

  function enableNFTOperator() public onlyOwner {
    preventNFTOperator = false;
    setInterfaceImplementation("ERC721Operator", this);
  }

  ///@notice sets the percentage of sale's values that the owner will receive for every sale
  function setOwnersCut(uint256 _newCut) public onlyOwner {
    ownersCut = _newCut;
  }
}
