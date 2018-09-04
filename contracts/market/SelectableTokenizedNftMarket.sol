pragma solidity ^0.4.24;
import "./StandardTokenizedNftMarket.sol";
import "../eip777/IEIP777TokensOperator.sol";
import "../eip721/ICommodityOperator.sol";


contract SelectableTokenizedNftMarket is StandardTokenizedNftMarket, IEIP777TokensOperator, ICommodityOperator {

  constructor(address[] _marketItems, address _owner) StandardTokenizedNftMarket(_marketItems, _owner) public {
    // delegate constructor
  }

  function buy(address _from, uint256 _tokenId, uint256 _amount) public {
    // _buy will throw if the bid or funds transfer fails todo jaycen fix static 0 addr
    require(address(this) == msg.sender);
    _buy(_from, _tokenId, _amount);
    _transfer(
      _from,
      msg.sender,
      _tokenId,
      _amount
    );
    // todo jaycen disable the above two lines and enable the following. Functionality is ok, but it breaks tests
    // uint256 newSaleAmount = _buy(_from, _tokenId, _amount);
    // if (newSaleAmount != _amount) {
    //     _split(_tokenId, msg.sender, _amount);
    // } else {
    //     _transfer(_from, msg.sender, _tokenId, _amount);
    // }
  }

  /// @dev erc820 introspection : handler invoked when
  /// this contract is made an operator for a commodity
  function madeOperatorForCommodity(
    address,
    address from,
    address,
    uint tokenId,
    uint256,
    bytes _userData,
    bytes
  ) public {
    uint256 price = ConversionUtils.bytesToUint(_userData);
    require(
      address(commodityContract) == msg.sender,
      "Only the commodity contract can use 'madeOperatorForCommodity'"
    );
    if (preventCommodityOperator) {
      revert("This contract does not currently support being made an operator of commodities");
    }
    //todo jaycen can we figure out how to do this passing in a CommodityLib.Commodity struct (I was having solidity errors but it would be ideal)
    createSale(
      tokenId,
      1,
      1,
      from,
      price,
      _userData
    );
  }

  /// @notice NOT IMPLEMENTED YET, BUT NEEDED FOR INTERFACE FULFILLMENT
  /// This function is called by the CRC contract when this contract
  /// has lost authorization for a particular commodity. Since authorizations are
  /// what create the sale listings, is the market later loses authorization,
  /// then it needs to remove the sale from the queue (failure to do so would result in the
  /// market not being able to distribute CRCs to the buyer). Since there is also no way to
  /// Modify the queue, it is adamant that the CRC is removed from
  /// the queue or the result will be a broken market.
  /// @dev this function uses erc820 introspection : handler invoked when
  /// this contract is revoked an operator for a commodity
  /// @param tokenId the crc to remove from the FIFO sale queue
  function revokedOperatorForCommodity(
    address, // operator,
    address, // from,
    address, // to,
    uint tokenId,
    uint256, // value,
    bytes, // userData,
    bytes // operatorData
  ) public {
    require(
      address(commodityContract) == msg.sender,
      "Only the commodity contract can use 'revokedOperatorForCommodity'"
    );
    if (preventCommodityOperator) {
      revert("This contract does not currently support being revoked an operator of commodities");
    }
    //todo jaycen can we figure out how to do this passing in a CommodityLib.Commodity struct (I was having solidity errors but it would be ideal -- might be possible using eternal storage, passing hash of struct and then looking up struct values <-- would be VERY cool)
    //removeSale(tokenId);
  }


  /// @dev erc820 introspection : handler invoked when this contract
  /// is made an operator for an erc777 token
  function madeOperatorForTokens(
    address,
    address from,
    address,
    uint256 amount,
    bytes _userData,
    bytes
  ) public {
    require(
      address(tokenContract) == msg.sender,
      "Only the commodity contract can use 'madeOperatorForTokens'"
    );
    if (preventTokenOperator) {
      revert("This contract does not currently support being revoked an operator of tokens");
    }
    //todo either use from param and remove from off chain, or require from param = encoded ata from param
    require(_executeCall(address(this), 0, _userData)); // use operator as to param?
    //todo jaycen fix hard-codes (right now its only possible to buy a crc with ID 0 in selectable mode)
    //buy(from, 0, amount);
  }

  function createSale(
    uint256 _tokenId,
    uint64 _category,
    uint32 _saleType,
    address _seller,
    uint256 _value,
    bytes _misc
  ) public {
    _createSale(
      _tokenId,
      _category,
      _saleType,
      _seller,
      _value,
      _misc
    );
  }

  function _executeCall(address to, uint256 value, bytes data) private returns (bool success) {
    assembly { // solium-disable-line security/no-inline-assembly
      success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }

}