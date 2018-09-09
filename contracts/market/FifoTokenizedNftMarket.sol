pragma solidity ^0.4.24;
import "./StandardTokenizedNftMarket.sol";
import "../eip777/ERC777TokensOperator.sol";
import "../eip721/IERC721Operator.sol";
import "../../node_modules/zeppelin-solidity/contracts//math/SafeMath.sol";


contract FifoTokenizedNftMarket is StandardTokenizedNftMarket, ERC777TokensOperator, IERC721Operator {
  using SafeMath for uint256;

  int[] public nftsForSale;

  constructor(address[] _marketItems, address _owner) StandardTokenizedNftMarket(_marketItems, _owner) public {
    // delegate constructor
  }

  function getEarliestSale() public view returns (uint, uint) {
    if (nftsForSale.length >= 0) {
      for (uint i = 0; i < nftsForSale.length; i = i.add(1) ){
        if (nftsForSale[i] >= 0) {
          return (uint(nftsForSale[i]), i);
        }
      }
    }
    else
      revert("Invalid sale index");
  }

  function buy(address _buyer, uint256 _amount) private {
    var (nftIndex, saleIndex) = getEarliestSale();

    uint256 newSaleAmount = _buy(_buyer, nftIndex, _amount);
    if (newSaleAmount != 0) {
      //_split(nftIndex, _buyer, _amount);
    } else {
      _transfer(
        _buyer,
        msg.sender,
        nftIndex,
        _amount
      );
      nftsForSale[saleIndex] = -1;
    }
  }

  /// @notice This function is called by the CRC contract when this contract
  /// is given authorization to send a particular NFT. When such happens,
  /// a sale for the CRC is created and added to the bottom of the FIFO queue
  /// @param tokenId the crc to remove from the FIFO sale queue
  /// @param from the owner of the crc, and the sale proceed recipient
  /// @param value the number of crcs in a bundle to list for sale
  /// @param userData data passed by the user
  /// @dev this function uses erc820 introspection : handler invoked when
  /// this contract is made an operator for a NFT
  function madeOperatorForNFT(
    address, // operator,
    address from,
    address, // to,
    uint tokenId,
    uint256 value,
    bytes userData,
    bytes // operatorData
  ) public {
    require(
      address(nft) == msg.sender,
      "Only the NFT contract can invoke 'madeOperatorForNFT'"
    );
    if (preventNFTOperator) {
      revert("This contract does not currently allow being made the operator of NFTs");
    }
    createSale(
      tokenId,
      1,//todo remove hard-code
      2,
      from,
      value,
      userData
    );
  }

  /// @notice This function is called by the CRC contract when this contract
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
      "Only the NFT contract can invoke 'revokedOperatorForNFT'"
    );
    if (preventNFTOperator) {
      revert("This contract does not currently allow being revoked the operator of NFTs");
    }
    removeSale(tokenId);
  }

  /// @dev erc820 introspection : handler invoked when this contract
  ///  is made an operator for an erc777 token
  function madeOperatorForTokens(
    address, // operator,
    address buyer,
    address, // to,
    uint256 amount,
    bytes, // userData,
    bytes // operatorData
  ) public {
    if (preventTokenOperator) {
      revert("This contract does not currently allow being made the operator of tokens");
    }
    buy(buyer, amount);
  }

  //todo only allow from this address (cant make private due to operatorsend data)
  function createSale(
    uint256 _tokenId,
    uint64 _category,
    uint32 _saleType,
    address _seller,
    uint256 _value,
    bytes _misc
  ) private {
    _createSale(
      _tokenId,
      _category,
      _saleType,
      _seller,
      _value,
      _misc
    );
    nftsForSale.push(int(_tokenId)); //todo nftsforsale
  }

  function removeSale(uint256 _tokenId) private { //todo onlyThisContract modifier
    _removeSale(_tokenId);
    for (uint i = 0; i < nftsForSale.length; i++ ) {
      if (uint(nftsForSale[i]) == _tokenId) {
        nftsForSale[i] = -1;
        return;
      }
    }
  }
}