pragma solidity ^0.4.24;

import "./ICommodityRecipient.sol";
import "./IERC721Operator.sol";
import "./ICommoditySender.sol";
import "../eip820/contracts/ERC820Implementer.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol";


//todo rename to AdvancedERC721
contract AdvancedERC721 is ERC721Mintable, ERC721Pausable, ERC820Implementer {
  using SafeMath for uint256;

  /*** EVENTS ***/
  event AuthorizedOperator(address operator, address indexed tokenHolder); //todo rename
  event RevokedOperator(address indexed operator, address indexed tokenHolder); //todo write cancel sale using this

  event Send(
    address  from,
    address  to,
    uint256 tokenId,
    bytes userData,
    address  operator,
    bytes operatorData
  );

  constructor(
    string _name,
    string _symbol,
    address _owner //todo fix/rm this
  ) public ERC721Full(_name, _symbol) {
    // owner = _owner;
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    setInterfaceImplementation("IERC721", this);
    //todo register advanced721 interfaces instead
  }

  //todo can this be used with safetransferfrom
  /** @dev Notify a recipient of received tokens. */
  function callRecipient(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "Only a nft owner can use 'callRecipient'");
    address recipientImplementation = interfaceAddr(_to, "IERC721Recipient");
    if (recipientImplementation != 0) {
      ICommodityRecipient(recipientImplementation).commodityReceived( //todo erc721 recipient
        _operator,
        _from,
        _to,
        _tokenId,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support this NFT");
    }
  }

  function callOperator(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _value,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    require(ownerOf(_tokenId) == msg.sender, "Only the owner can use 'callOperator'");
    address recipientImplementation = interfaceAddr(_to, "IERC721Operator");
    if (recipientImplementation != 0) {
      IERC721Operator(recipientImplementation).madeOperatorForNFT(
        _operator,
        _from,
        _to,
        _tokenId,
        _value,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support being an operator of this NFT");
    }
  }

  //todo use this to cancel sale
  /// @notice If the recipient address (_to/_operator param) is listed in the registry as supporting
  ///   the IERC721Operator interface, it calls the revokedOperatorForNFT
  ///   function.
  /// @param _operator The _operator being revoked
  /// @param _from the owner of the NFT
  /// @param _to the operator address to introspect for IERC721Operator interface support
  /// @param _tokenId the NFT index
  /// @param _value the value of the NFT to revoke allowance for. This is currently unfinished.
  /// @param _userData the data to pass on behalf of the user. This is currently unsupported.
  /// @param _operatorData the data to pass on behalf of the operator. This is currently unsupported.
  /// @param _preventLocking used to prevent sending to contract addresses who are not supported by this NFT
  /// @dev This idea behind functions like this come from EIP 820
  function callRevokedOperator(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _value,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    require(
      ownerOf(_tokenId) == msg.sender,
      "Only an approved address can use 'callRevokedOperator'"
    );
    require(ownerOf(_tokenId) == msg.sender, "Only an owner of this NFT can use 'callRevokedOperator'");
    address recipientImplementation = interfaceAddr(_to, "IERC721Operator");
    if (recipientImplementation != 0) {
      IERC721Operator(recipientImplementation).revokedOperatorForNFT(
        _operator,
        _from,
        _to,
        _tokenId,
        _value,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support revocation of this NFT");
    }
  }
  //todo is this needed with safetransferfrom
  function callSender(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "Only an approved address can use 'callSender'");
    address recipientImplementation = interfaceAddr(_to, "IERC721Sender");
    if (recipientImplementation != 0) {
      ICommoditySender(recipientImplementation).commodityToSend( //todo nftsender
        _operator,
        _from,
        _to,
        _tokenId,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support sending of NFTs");
    }
  }

  /** @dev Perform an actual send of tokens. */
  function doSend(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    address _operator,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    callSender(
      _operator,
      _from,
      _to,
      _tokenId,
      _userData,
      _operatorData,
      false
    );
    require(_to != address(0), "You can not send to the burn address (0x0)"); // forbid sending to 0x0 (=burning)
    require(_tokenId >= 0, "You can only send a valid NFT (>=0)");      // only send positive amounts
    require(
      _isApprovedOrOwner(msg.sender, _tokenId),
      "Only an approved operator or the owner can send this nft"
    );

    safeTransferFrom(_from, _to, _tokenId);
    callRecipient(
      _operator,
      _from,
      _to,
      _tokenId,
      _userData,
      _operatorData,
      _preventLocking
    );

    emit Send(
      _from,
      _to,
      _tokenId,
      _userData,
      _operator,
      _operatorData
    );
  }

  /** @notice Check whether an address is a regular address or not. */
  function isRegularAddress(address _addr) internal view returns(bool) {
    if (_addr == 0) {
      return false;
    }
    uint size;
    assembly { size := extcodesize(_addr) } //solium-disable-line security/no-inline-assembly
    return size == 0;
  }

  //todo is this needed in addition to safetransferfrom
  /** @notice Send '_value' amount of tokens to address '_to'. */
  function send(address _to, uint256 _tokenId) public {
    doSend(
      msg.sender,
      _to,
      _tokenId,
      "",
      msg.sender,
      "",
      true
    );
  }

  //todo is this needed in addition to safetransferfrom
  /** @notice Send '_value' amount of tokens to address '_to'. */
  function send(address _to, uint256 _tokenId, bytes _userData) public {
    doSend(
      msg.sender,
      _to,
      _tokenId,
      _userData,
      msg.sender,
      "",
      true
    );
  }

  // Todo jaycen : is sendFrom or operatorSend the accepted standard (check pre-launch) to protect from backward/thirdparty compatibility issues
  function operatorSend(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    address _operator,
    bytes _operatorData,
    bool _preventLocking
  ) public {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0), "You cannot send to the 0 address (0x0)");
    require(
      _isApprovedOrOwner(msg.sender, _tokenId),
      "Only an approved operator can send the NFT on the owner's behalf"
    );
    callRecipient(
      _operator,
      _from,
      _to,
      _tokenId,
      _userData,
      _operatorData,
      _preventLocking
    );

    // Reassign ownership, clear pending approvals, emit Transfer event.
    safeTransferFrom(_from, _to, _tokenId);
  }


  function approveAndCall(address _operator, uint256 _tokenId, bytes _data) public {
    approve(_operator, _tokenId);
    callOperator(
      _operator,
      msg.sender,
      _operator,
      _tokenId,
      0, //todo allow for fractional values to be passed by using the split function
      _data,
      "",
      false
    );
    emit AuthorizedOperator(_operator, msg.sender);

  }

  //todo fix this
  /** @notice Revoke a third party '_operator''s rights to manage (send) 'msg.sender''s tokens. */
  function revokeOperator(address _operator, uint256 _tokenId) public {
    //todo jaycen call operator to cancel sale on markets
    require(_operator != msg.sender, "You cannot revoke yourself as an operator");
    //require(_owns(msg.sender, _tokenId), "Only the owner of the NFT can revoke an operator");
    //mAuthorized[_operator][msg.sender] = false; //todo what is this
    callRevokedOperator(
      _operator,
      msg.sender,
      _operator,
      _tokenId,
      0, //todo fix this
      "",
      "",
      false
    );
    //todo fix this
    // address operator = commodityBundleIndexToApproved[_tokenId];
    // for(uint i = 0; i < commodityOperatorBundleApprovals[operator][msg.sender].length; i++){
    //   if(commodityOperatorBundleApprovals[operator][msg.sender][i] == _tokenId){
    //     _cumulativeAllowance[operator] = _cumulativeAllowance[operator].sub(commodities[_tokenId].value);
    //     delete commodityOperatorBundleApprovals[operator][msg.sender][i];
    //   }
    // }
    // delete commodityBundleIndexToApproved[_tokenId];
    emit RevokedOperator(_operator, msg.sender);
  }

  function mintWithoutId(address _to) public onlyMinter {
    uint256 tokenId = totalSupply();
    mint(_to, tokenId);
  }

}
