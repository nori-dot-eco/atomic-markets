pragma solidity ^0.4.24;
import "./StandardTokenizedNftMarket.sol";
import "../eip777/ERC777TokensOperator.sol";
import "../eip721/IERC721Operator.sol";


contract SelectableTokenizedNftMarket is StandardTokenizedNftMarket, ERC777TokensOperator, IERC721Operator {

  constructor(address[] _marketItems, address _owner) StandardTokenizedNftMarket(_marketItems, _owner) public {
    // delegate constructor
  }

  //todo, note, passing in buyer (as opposed to msg.sender) here is probaly not safe, look into this
  function buy(address _buyer, uint256 _tokenId, uint256 _amount) public {
    require(address(this) == msg.sender, "You can only call the buy function using callOperator on the token contract");
    _buy(_buyer, _tokenId, _amount);
    _transfer(
      _buyer,
      msg.sender,
      _tokenId,
      _amount
    );
  }

  /// @dev erc820 introspection : handler invoked when
  /// this contract is made an operator for a NFT
  function madeOperatorForNFT(
    address,
    address from,
    address,
    uint tokenId,
    uint256,
    bytes _userData,
    bytes
  ) public {
    require(
      address(nft) == msg.sender,
      "Only the NFT contract can use 'madeOperatorForNFT'"
    );
    if (preventNFTOperator) {
      revert("This contract does not currently support being made an operator of commodities");
    }
    require(_executeCall(address(this), 0, _userData), "_executeCall failed"); // use operator as to param?
  }

  /// @notice NOT IMPLEMENTED YET, BUT NEEDED FOR INTERFACE FULFILLMENT
  /// This function is called by the CRC contract when this contract
  /// has lost authorization for a particular NFT. Since authorizations are
  /// what create the sale listings, is the market later loses authorization,
  /// then it needs to remove the sale from the queue (failure to do so would result in the
  /// market not being able to distribute CRCs to the buyer). Since there is also no way to
  /// Modify the queue, it is adamant that the CRC is removed from
  /// the queue or the result will be a broken market.
  /// @dev this function uses erc820 introspection : handler invoked when
  /// this contract is revoked an operator for a NFT
  /// @param tokenId the crc to remove from the FIFO sale queue
  function revokedOperatorForNFT(
    address, // operator,
    address, // from,
    address, // to,
    uint tokenId,
    uint256, // value,
    bytes, // userData,
    bytes // operatorData
  ) public {
    require(
      address(nft) == msg.sender,
      "Only the NFT contract can use 'revokedOperatorForNFT'"
    );
    if (preventNFTOperator) {
      revert("This contract does not currently support being revoked an operator of NFTs");
    }
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
      "Only the token contract can use 'madeOperatorForTokens'"
    );
    if (preventTokenOperator) {
      revert("This contract does not currently support being revoked an operator of tokens");
    }
    //todo either use from param and remove from off chain, or require from param = encoded ata from param
    require(_executeCall(address(this), 0, _userData), "_executeCall failed"); // use operator as to param?
  }

  function createSale(
    address _seller,
    uint256 _tokenId,
    uint256 _value
  ) public {
    _createSale(
      _tokenId,
      uint64(0), //todo fix these params to not be static
      uint32(0),
      _seller,
      _value,
      "0x0"
    );
  }


  function _executeCall(address to, uint256 value, bytes data) private returns (bool success) {
    assembly { // solium-disable-line security/no-inline-assembly
      success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }

}