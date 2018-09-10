pragma solidity ^0.4.24;
import "./StandardTokenizedNftMarket.sol";
import "../eip777/ERC777TokensOperator.sol";
import "../eip721/IERC721Operator.sol";


contract PriceBasedTokenizedNftMarket is StandardTokenizedNftMarket, ERC777TokensOperator, IERC721Operator {

  constructor(
    address _nftContract,
    address _tokenContract
  ) StandardTokenizedNftMarket(_nftContract, _tokenContract) public {
    // delegate constructor
  }

  function buy(address _buyer, uint256 _nftId, uint256 _amount) public {
    require(address(this) == msg.sender, "You can only call the buy function using callOperator on the token contract");
    _buy(_buyer, _nftId, _amount);
    _transfer(
      _buyer,
      msg.sender,
      _nftId,
      _amount
    );
  }

  /// @dev erc820 introspection : handler invoked when
  /// this contract is made an operator for a NFT
  function madeOperatorForNFT(
    address,
    address _nftOwner,
    address,
    uint256 _nftId,
    uint256,
    bytes _userData,
    bytes
  ) public {
    (address seller,uint256 nftId, uint256 price) = decodeData(_userData);
    //Since we are relying on some relatively unsafe encoded assembly call code,
    //the following helps sanity check the viability of that call
    require(seller == _nftOwner, "The encoded sell function's seller param MUST be the address initiating the 'approveAndCall' function");
    require(nft.ownerOf(nftId) == seller, "Only the owner can initiate a sale for the specified NFT");
    require(price > 0, "You must set a price > 0");
    require(nftId == _nftId, "The encoded NFT ID to sale should equal the non encoded NFT ID");
    require(
      address(nft) == msg.sender,
      "Only the NFT contract can use 'madeOperatorForNFT'"
    );
    if (preventNFTOperator) {
      revert("This contract does not currently support being made an operator of commodities");
    }
    require(_executeCall(address(this), 0, _userData), "_executeCall failed");
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
  /// @param _nftId the crc to remove from the FIFO sale queue
  function revokedOperatorForNFT( //todo
    address, // operator,
    address, // from,
    address, // to,
    uint _nftId,
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
    //removeSale(_nftId);
  }


  /// @dev erc820 introspection : handler invoked when this contract
  /// is made an operator for an erc777 token
  function madeOperatorForTokens(
    address,
    address _tokenOwner,
    address,
    uint256 _value,
    bytes _userData,
    bytes
  ) public {
    (address buyer, uint256 nftId, uint256 price) = decodeData(_userData); //solium-disable-line no-unused-vars
    //Since we are relying on some relatively unsafe encoded assembly call code,
    //the following helps sanity check the viability of that call
    require(buyer == _tokenOwner, "The encoded buy function's buyer param MUST be the address initiating the 'approveAndCall' function");
    require(tokenContract.balanceOf(_tokenOwner) >= price, "You must have a balance >= the spend value");
    require(price > 0 && price == _value, "You must set a price > 0");
    require(
      address(tokenContract) == msg.sender,
      "Only the token contract can use 'madeOperatorForTokens'"
    );
    if (preventTokenOperator) {
      revert("This contract does not currently support being revoked an operator of tokens");
    }
    require(_executeCall(address(this), 0, _userData), "_executeCall failed"); // use operator as to param?
  }

  function createSale(
    address _seller,
    uint256 _nftId,
    uint256 _value
  ) public {
    _createSale(
      _nftId,
      _seller,
      _value
    );
  }

  /// @dev executes a function call using pre encoded data
  function _executeCall(address _to, uint256 _value, bytes _data) private returns (bool success) {
    assembly { // solium-disable-line security/no-inline-assembly
      success := call(gas, _to, _value, add(_data, 0x20), mload(_data), 0, 0)
    }
  }

  /// @dev helper function to decode the buy and sell pre-encoded function data
  function decodeData(bytes _encodedParam) public pure returns (address addr, uint256 id, uint256 price) {
    uint256 btsptr;
    /* solium-disable-next-line security/no-inline-assembly */
    assembly {
        btsptr := add(_encodedParam, /*BYTES_HEADER_SIZE*/36)
        addr := mload(btsptr)
        btsptr := add(_encodedParam, /*BYTES_HEADER_SIZE*/68)
        id := mload(btsptr)
        btsptr := add(_encodedParam, /*BYTES_HEADER_SIZE*/100)
        price := mload(btsptr)
    }
  }
}