pragma solidity ^0.4.24;
import "./MarketLib.sol";
import "../eip820/contracts/ERC820Implementer.sol";
import "../eip820/contracts/ERC820ImplementerInterface.sol";
import "../../node_modules/zeppelin-solidity/contracts//math/SafeMath.sol";
import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Market is Ownable, ERC820Implementer, ERC820ImplementerInterface {
  using SafeMath for uint256;

  MarketLib.Market[] public marketItems;
  bool internal preventTokenReceived = true;
  bool internal preventTokenOperator = true;
  bool internal preventCommodityReceived = true;
  bool internal preventCommodityOperator = true;

  constructor(address[] _marketItems, address _owner) public {
    for (uint i = 0;  i < _marketItems.length; i = i.add(1)) {
      _createMarketItem(_marketItems[i]);
    }
    owner = _owner;
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    preventTokenOperator = false;
    setInterfaceImplementation("IEIP777TokensOperator", this);
    preventCommodityOperator = false;
    setInterfaceImplementation("ICommodityOperator", this);
  }

  //todo remove?
  function _createMarketItem (address _marketItem) private onlyOwner {
    MarketLib.Market memory marketItem = MarketLib.Market({
        tokenContract: address(_marketItem)
    });
    marketItems.push(marketItem);
  }

  function canImplementInterfaceForAddress(address, bytes32) public view returns(bytes32) {
    return ERC820_ACCEPT_MAGIC;
  }

  function enableEIP777TokensOperator() public onlyOwner {
    preventTokenOperator = false;
    setInterfaceImplementation("IEIP777TokensOperator", this);
  }

  function enableCommodityOperator() public onlyOwner {
    preventCommodityOperator = false;
    setInterfaceImplementation("ICommodityOperator", this);
  }
}
