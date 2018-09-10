pragma solidity ^0.4.24;
import "../eip820/contracts/ERC820Implementer.sol";
import "../eip820/contracts/ERC820ImplementerInterface.sol";
import "../../node_modules/zeppelin-solidity/contracts//math/SafeMath.sol";
import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Market is Ownable, ERC820Implementer, ERC820ImplementerInterface {
  using SafeMath for uint256;

  bool internal preventTokenReceived = true;
  bool internal preventTokenOperator = true;
  bool internal preventNFTReceived = true;
  bool internal preventNFTOperator = true;

  constructor(address _owner) public {
    owner = _owner;
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    preventTokenOperator = false;
    setInterfaceImplementation("ERC777TokensOperator", this);
    preventNFTOperator = false;
    setInterfaceImplementation("IERC721Operator", this);
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
    setInterfaceImplementation("IERC721Operator", this);
  }
}
