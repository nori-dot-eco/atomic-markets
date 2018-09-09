pragma solidity ^0.4.24;
import "./MarketLib.sol";
import "../eip777/ERC777Token.sol";
import "./Market.sol";
import "../../node_modules/zeppelin-solidity/contracts//math/SafeMath.sol";
import "../utils/ConversionUtils.sol";
import "../../node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract StandardTokenizedNftMarket is Market {
  using SafeMath for uint256; //todo jaycen PRELAUNCH - make sure we use this EVERYWHERE its needed

  /// @dev Reference to contract tracking NFT ownership
  ERC721 public nft; //todo rename this
  /// @dev Reference to contract tracking token ownership
  ERC777Token public tokenContract;

  mapping (uint256 => MarketLib.Sale) public tokenIdToSell;

  event SaleSuccessful(uint256 tokenId, uint256 value, address buyer);
  event SaleCreated(uint256 tokenId, uint64 category, uint32 saleType, address seller, uint256 value, bytes misc, uint64 startedAt);
  event NFTReceived(address sender);

  constructor(address[] _marketItems, address _owner) Market(_marketItems, _owner) public {
    setNFTContract(_marketItems[0]);
    setTokenContract(_marketItems[1]);
    // and delegate constructor
  }

  function setNFTContract (address _nftContract) internal onlyOwner {
    nft = ERC721(_nftContract); //todo is this the best way to do this
  }

  function setTokenContract (address _tokenContract) internal onlyOwner {
    tokenContract = ERC777Token(_tokenContract);
  }

  function _addSale(uint256 _tokenId, MarketLib.Sale _sale) private {

    tokenIdToSell[_tokenId] = _sale;

    emit SaleCreated(
      uint256(_tokenId),
      uint64(_sale.category),
      uint32(_sale.saleType),
      address(_sale.seller),
      _sale.value,
      bytes(_sale.misc),
      uint64(now) // solium-disable-line security/no-block-members
    );
  }

  /// @dev transfers buyers token to seller.
  /// Does NOT transfer sellers NFT (token) to buyer
  function _buy(address _buyer, uint256 _tokenId, uint256 _amount) internal returns (uint256) {
    MarketLib.Sale storage sale = tokenIdToSell[_tokenId];
    require(_isOnSale(sale), "You can only buy a NFT that is currently on sale");
    require(_buyer != sale.seller, "You cannot buy your own NFT");
    require(
      _amount <= sale.value,
      "You can only purchase a value of the current NFT that is <= its bundle value"
    );

    address seller = sale.seller;

    //todo fix this (was initially written for the CRC)
    if (_amount == sale.value
    ) {
      _removeSale(_tokenId);
    } else if (_amount < sale.value && _amount > 0) {
      sale.value = _updateSale(_tokenId, _amount);
    } else {
      revert("Invalid value specification");
    }

    if (_amount > 0) {
      // todo add market fee taking logic
      //  Calculate the seller's cut.
      // (NOTE: _computeCut() is guaranteed to return a
      //  number <= _amount, so this subtraction can't go negative.)
      // uint256 marketCut = _computeCut(_amount);
      // uint256 sellerProceeds = sale.value - marketCut;

      emit Buying(_buyer, seller);
      tokenContract.operatorSend(
        _buyer,
        seller,
        _amount,
        "0x0",
        "0x0"
      );
    }

    emit SaleSuccessful(_tokenId, _amount, _buyer);

    return sale.value;
  }
  event Buying(address buyer, address seller);

  function _createSale(
    uint256 _tokenId,
    uint64 _category,
    uint32 _saleType,
    address _seller,
    uint256 _value,
    bytes _misc
  ) internal {
    require(nft.getApproved(_tokenId) == address(this), "The market is not currently an operator for this NFT");
    MarketLib.Sale memory sale = MarketLib.Sale(
      uint256(_tokenId),
      uint64(_category),
      uint32(_saleType),
      _seller,
      uint256(_value),
      bytes(_misc),
      uint64(block.timestamp) //solium-disable-line security/no-block-members
    );
    _addSale(_tokenId, sale);
  }

  /// @dev Returns true if the NFT is on sale.
  /// @param _sale - sale to check.
  function _isOnSale(MarketLib.Sale storage _sale) internal view returns (bool) {
    return (_sale.startedAt > 0);
  }

  /// @dev Returns true if the claimant owns the token.
  /// @param _claimant - Address claiming to own the token.
  /// @param _tokenId - ID of token whose ownership to verify.
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return (nft.ownerOf(_tokenId) == _claimant);
  }

  // todo jaycen via revokeOperator -- also do we need something similar if someone tries to auth tokens when no crc sales are available? Not sure ive tested for this
  /// @dev Removes a sale from the list of open sales.
  /// @param _tokenId - ID of NFT on sale.
  function _removeSale(uint256 _tokenId) internal {
    require(nft.getApproved(_tokenId) == address(this), "The market is not currently the operator for this value of tokens");
    delete tokenIdToSell[_tokenId];
  }

  // todo
  /// @dev Removes a sale from the list of open sales.
  /// @param _tokenId - ID of NFT on sale.
  function _updateSale(uint256 _tokenId, uint256 _amount) internal returns (uint256) {
    //todo jaycen only allow this to be called when the market invokes it (require it is less than original and > 0)
    uint256 newSaleValue = tokenIdToSell[_tokenId].value.sub(_amount);
    tokenIdToSell[_tokenId].value = newSaleValue;
    return newSaleValue;
  }

  /// @dev Transfers an NFT owned by this contract to another address.
  ///  Returns true if the transfer succeeds.
  /// @param _buyer - owner of the NFT to transfer from (via operator sending).
  /// @param _tokenId - ID of token to transfer.
  function _transfer(
    address _buyer,
    address, //to
    uint256 _tokenId,
    uint256 // amount
  ) internal {
    address seller = nft.ownerOf(_tokenId);
    nft.safeTransferFrom(
      seller,
      _buyer,
      _tokenId,
      "0x0"
    );
  }

  function getSalePrice(uint256 _tokenId) public view returns (uint) {
    return tokenIdToSell[_tokenId].value;
  }

  function getSaleSeller(uint256 _tokenId) public view returns (address) {
    return tokenIdToSell[_tokenId].seller;
  }
}