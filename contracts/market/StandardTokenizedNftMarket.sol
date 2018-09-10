pragma solidity ^0.4.24;
import "./MarketLib.sol";
import "../eip777/ERC777Token.sol";
import "./Market.sol";
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract StandardTokenizedNftMarket is Market {
  using SafeMath for uint256;

  /// @dev Reference to contract tracking NFT ownership
  ERC721 public nft;
  /// @dev Reference to contract tracking token ownership
  ERC777Token public tokenContract;

  mapping (uint256 => MarketLib.Sale) public nftIdToSell;

  event SaleSuccessful(uint256 nftId, uint256 sellersProfit, address buyer, address owner, uint256 ownersProfit);
  event SaleCreated(uint256 nftId, address seller, uint256 value, uint64 startedAt);
  event NFTReceived(address sender);

  constructor(address _nftContract, address _tokenContract) Market() public {
    setNFTContract(_nftContract);
    setTokenContract(_tokenContract);
    // and delegate constructor
  }

  function setNFTContract (address _nftContract) internal onlyOwner {
    nft = ERC721(_nftContract);
  }

  function setTokenContract (address _tokenContract) internal onlyOwner {
    tokenContract = ERC777Token(_tokenContract);
  }

  function _addSale(uint256 _nftId, MarketLib.Sale _sale) private {
    nftIdToSell[_nftId] = _sale;
    emit SaleCreated(
      _nftId,
      address(_sale.seller),
      _sale.value,
      uint64(now) // solium-disable-line security/no-block-members
    );
  }

  /// @dev transfers buyers token to seller.
  /// Does NOT transfer sellers NFT (token) to buyer
  function _buy(address _buyer, uint256 _nftId, uint256 _amount) internal returns (uint256) {
    MarketLib.Sale storage sale = nftIdToSell[_nftId];
    require(_isOnSale(sale), "You can only buy a NFT that is currently on sale");
    require(_buyer != sale.seller, "You cannot buy your own NFT");
    require(
      _amount <= sale.value,
      "You can only purchase a value of the current NFT that is <= its bundle value"
    );

    address seller = sale.seller;
    uint256 sellersProfit = sale.value;
    uint256 ownersProfit;

    if (_amount == sale.value) {
      _removeSale(_nftId);
    } else {
      revert("Invalid value specification");
    }

    if (sellersProfit > 0) {
      ownersProfit = _calculateOwnerCut(sellersProfit);
      sellersProfit = sellersProfit.sub(ownersProfit);

      tokenContract.transferFrom( // although you can also do this with operatorSend, it's safer to use an allowance
        _buyer,
        seller,
        sellersProfit
      );
      tokenContract.transferFrom( // although you can also do this with operatorSend, it's safer to use an allowance
        _buyer,
        owner(),
        ownersProfit
      );
    } else {
      revert("Sale was unsuccessful: Invalid price");
    }
    emit SaleSuccessful(
      _nftId,
      sellersProfit,
      _buyer,
      owner(),
      ownersProfit
    );
    return sale.value;
  }

  function _createSale(
    uint256 _nftId,
    address _seller,
    uint256 _value
  ) internal {
    require(nft.getApproved(_nftId) == address(this), "The market is not currently an operator for this NFT");
    MarketLib.Sale memory sale = MarketLib.Sale(
      _nftId,
      _seller,
      _value,
      uint64(block.timestamp) //solium-disable-line security/no-block-members
    );
    _addSale(_nftId, sale);
  }

  /// @dev Returns true if the NFT is on sale.
  /// @param _sale - sale to check.
  function _isOnSale(MarketLib.Sale storage _sale) internal view returns (bool) {
    return (_sale.startedAt > 0);
  }

  /// @dev Returns true if the claimant owns the token.
  /// @param _claimant - Address claiming to own the token.
  /// @param _nftId - ID of token whose ownership to verify.
  function _owns(address _claimant, uint256 _nftId) internal view returns (bool) {
    return (nft.ownerOf(_nftId) == _claimant);
  }

  // todo jaycen via revokeOperator -- also do we need something similar if someone tries to auth tokens when no crc sales are available? Not sure ive tested for this
  /// @dev Removes a sale from the list of open sales.
  /// @param _nftId - ID of NFT on sale.
  function _removeSale(uint256 _nftId) internal {
    delete nftIdToSell[_nftId];
  }

  /// @dev Transfers an NFT owned by this contract to another address.
  ///  Returns true if the transfer succeeds.
  /// @param _buyer - owner of the NFT to transfer from (via operator sending).
  /// @param _nftId - ID of token to transfer.
  function _transfer(
    address _buyer,
    address, //to
    uint256 _nftId,
    uint256 // amount
  ) internal {
    address seller = nft.ownerOf(_nftId);
    nft.safeTransferFrom(
      seller,
      _buyer,
      _nftId,
      "0x0"
    );
  }

  function _calculateOwnerCut(uint256 _saleAmount) internal view returns(uint256) {
    return _saleAmount.mul(ownersCut).div(100);
  }

  function getSalePrice(uint256 _nftId) public view returns (uint) {
    return nftIdToSell[_nftId].value;
  }

  function getSaleSeller(uint256 _nftId) public view returns (address) {
    return nftIdToSell[_nftId].seller;
  }

  function getSaleStartedAt(uint256 _nftId) public view returns (uint256) {
    return nftIdToSell[_nftId].startedAt;
  }
}