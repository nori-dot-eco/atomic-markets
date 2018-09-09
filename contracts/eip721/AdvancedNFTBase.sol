pragma solidity ^0.4.24;

import "./ICommodityRecipient.sol";
import "./ICommodityOperator.sol";
import "./ICommoditySender.sol";
import "../eip820/contracts/ERC820Implementer.sol";
// import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
// import "./ICommodity.sol"; //todo Iadvancedtoken
import "./CommodityLib.sol";
//import "./IMintableCommodity.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol";


//AdvancedERC721
contract AdvancedNFTBase is ERC721Mintable, ERC721Pausable, ERC820Implementer {
  using SafeMath for uint256; //todo jaycen PRELAUNCH - make sure we use this EVERYWHERE its needed

  /*** EVENTS ***/
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event AuthorizedOperator(address operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
  /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a commodity
  ///  ownership is assigned, including creations.
 // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Send(
    address  from,
    address  to,
    uint256 tokenId,
    bytes userData,
    address  operator,
    bytes operatorData
  );
  event Burnt(address indexed from, uint256 tokenId);
  event Minted(address indexed to, uint commodityId, uint256 amount, address indexed operator, bytes operatorData);
  event InsufficientPermission(address sender, bytes operatorData, uint256 value, bytes misc);

  uint256 internal mTotalSupply;
  bool public onlyParticipantCallers = true;

  /// @dev A mapping from commodity IDs to the address that owns them. All commoditys have
  ///  some valid owner address
  mapping (uint256 => address) public commodityIndexToOwner;

  // @dev A mapping from owner address to count of commoditys that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) ownershipBundleCount;

  /// @dev A mapping from commodity IDs to an address that has been approved to call
  ///  transferFrom(). Each commodity can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public commodityBundleIndexToApproved;

  /// @dev A mapping from operator addresses to an allowance balance which the operator has
  /// the authority to send on behalf of a particular commodity owner.
  mapping (address => mapping (address => uint256[])) public commodityOperatorBundleApprovals;


  /// @dev A mapping from commodity IDs to an address that has been approved to split
  ///  this commodity. Each commodity can only have one approved
  ///  address for siring at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public commodityAllowedToAddress;

  //mapping(address => uint) internal   _balances; // using ownedTokensCount as per zeppelin contract
  mapping(address => uint) internal _cumulativeAllowance;

  mapping(address => mapping(address => bool)) private mAuthorized;
  mapping(address => mapping(address => uint256)) private mAllowed;

  bool private _initialized;
  string private mName;
  string private mSymbol;

  constructor(
    string _name,
    string _symbol,
    address _owner //todo fix/rm this
  ) public ERC721Full(_name, _symbol) {
    // owner = _owner;
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    //setInterfaceImplementation("ICommodity", this);
    //setInterfaceImplementation("IMintableCommodity", this); //todo register rc721 interfaces instead
    onlyParticipantCallers = true; //todo remove this
  }

  /// @notice Returns the total number of crcs currently in existence. todo jaycen can this be uint64 and also should this instead return .value of all comms?
  function getTotalSupplyByCategory(uint64 _category) public view returns (uint256) {
    return getTotalSupply(_category);
  }

  function totalSupply() public view returns (uint256) {
    return getTotalSupplyByCategory(1); //todo jaycen fix this static var when we understand crc tiers more
  }

  /// @dev An array containing the Commodity struct for all commodities in existence. The ID
  ///  of each commodity is actually an index into this array.
  CommodityLib.Commodity[] public commodities;

  function getTotalSupply(uint64 _category) public view returns (uint256) {
    uint256 count;
    for (uint256 i = 0; i < commodities.length; i = i.add(1)) {
      if (commodities[i].category == _category) {
        count = count.add(1);
      }
    }
    return count;
  }

  function getCommodityValueByIndex(uint256 _index) public view returns (uint256) {
    return commodities[_index].value;
  }

  function getCommodityCategoryByIndex(uint256 _index) public view returns (uint256) {
    return commodities[_index].category;
  }

  function getTotalSupply() public view returns (uint256) {
    return commodities.length.sub(1);
  }

  function _totalSupply() internal view returns (uint256) {
    return commodities.length.sub(1);
  }

  /// @dev Checks if a given address currently has transferApproval for a particular commodity.
  /// @param _claimant the address we are confirming commodity is approved for.
  /// @param _tokenId commodity id, only valid when > 0
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return commodityBundleIndexToApproved[_tokenId] == _claimant;
  }

  // /// @dev Checks if a given address is the current owner of a particular commodity.
  // /// @param _claimant the address we are validating against.
  // /// @param _tokenId commodity id, only valid when > 0
  // function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
  //   return commodityIndexToOwner[_tokenId] == _claimant;
  // }

  //todo jaycen make a lockable commodity interface?
  /// @dev check if commodity is locked
  /// @param _tokenId commodity id
  function _unlocked(uint256 _tokenId) internal view returns (bool) {
    return commodities[_tokenId].locked == false;
  }

  // /// @dev Assigns ownership of a specific commodity to an address. Currently, you can only
  // /// transfer a single bundle per transaction.
  // function _transfer(address _from, address _to, uint256 _tokenId) internal {
  //   //require commodity not locked/retired
  //   require(_unlocked(_tokenId), "You cannot transfer a locked/retired commodity");

  //   // increment bundle count and total balance
  //   ownershipBundleCount[_to] = ownershipBundleCount[_to].add(1);
  //   _ownedTokensCount[_to] = _ownedTokensCount[_to].add(commodities[_tokenId].value);
  //   // transfer ownership of bundle
  //   commodityIndexToOwner[_tokenId] = _to;

  //   // When creating new commodities _from is 0x0, but we can't account that address.
  //   if (_from != address(0)) {
  //   ownedTokensCount[_from] = ownedTokensCount[_from].sub(commodities[_tokenId].value);
  //     if(ownershipBundleCount[_from] > 0){
  //       ownershipBundleCount[_from] = ownershipBundleCount[_from].sub(1);
  //     }

  //     // clear any previously approved ownership exchange
  //     address operator = commodityBundleIndexToApproved[_tokenId];
  //     for(uint i = 0; i < commodityOperatorBundleApprovals[operator][_from].length; i = i.add(1)){
  //       if(commodityOperatorBundleApprovals[operator][_from][i] == _tokenId){
  //         _cumulativeAllowance[operator] = _cumulativeAllowance[operator].sub(commodities[_tokenId].value);
  //         delete commodityOperatorBundleApprovals[operator][_from][i];
  //       }
  //     }
  //     delete commodityBundleIndexToApproved[_tokenId];

  //     //retire commodity
  //     commodities[_tokenId].locked = true;
  //   }
  //   emit Transfer(_from, _to, _tokenId);
  // }

  // /// @notice Returns the total value of crcs owned by a specific address.
  // /// @param _owner The owner address to check.
  // function balanceOf(address _owner) public view returns (uint256 count) {
  //   return ownedTokensCount[_owner];
  // }

  /// @notice Returns the number of crc bundles owned by a specific address.
  /// @param _owner The owner address to check.
  function bundleBalanceOf(address _owner) public view returns (uint256 count) {
    return ownershipBundleCount[_owner];
  }

  /// @notice Returns the total operator value of crc allowances for all bundles of
  ///   a givven address
  /// @param _operator The _operator address to check allowances of.
  /// @param _owner The address of one of the commodity owners that the operator
  ///   has an allowance for.
  /// @return totalValue The total allowance value of an operator for a given owner
  function allowanceForAddress(address _operator, address _owner) public view returns (uint256 totalValue) {
    // todo total allowance balance of all addresses combined?
    uint totalAllowance = 0;
    if(commodityBundleIndexToApproved[0] == _operator){
      totalAllowance = totalAllowance.add(commodities[0].value);
    }
    for(uint i = 0; i < commodityOperatorBundleApprovals[_operator][_owner].length; i = i.add(1)){
      if(commodityOperatorBundleApprovals[_operator][_owner][i] != 0){
        totalAllowance = totalAllowance.add(commodities[commodityOperatorBundleApprovals[_operator][_owner][i]].value);
      }
    }
    return totalAllowance;
  }

  /// @notice Returns the total operator value of crc allowances for all bundles of
  ///   a given address
  /// @param _operator The _operator address to check allowances of.
  ///   has an allowance for.
  /// @return totalValue The total allowance value of an operator for a given owner
  function cumulativeAllowanceOf(address _operator) public view returns (uint256 totalValue) {
    return _cumulativeAllowance[_operator];
  }

  /// @notice Returns the number of crc bundles owned by a specific address.
  /// @param _operator The operator address to check.
  /// @param _owner The owner address to check.
  function bundleAllowanceForAddress(address _operator, address _owner) public view returns (uint256 count) {
    uint totalBundleAllowance = 0;
    if(commodityBundleIndexToApproved[0] == _operator){
      totalBundleAllowance = totalBundleAllowance.add(1);
    }
    for(uint i = 0; i < commodityOperatorBundleApprovals[_operator][_owner].length; i = i.add(1)){
      if(commodityOperatorBundleApprovals[_operator][_owner][i] != 0){
        totalBundleAllowance = totalBundleAllowance.add(1);
      }
    }
    return totalBundleAllowance;
  }

  // /** @notice Sample burn function to showcase the use of the 'Burn' event. */
  // function burn(address _tokenHolder, uint256 _tokenId) public returns(bool)  {
  //   require(_owns(msg.sender, _tokenId), "Only the commodity owner can burn a commodity");

  //   ownershipBundleCount[_tokenHolder] = ownershipBundleCount[_tokenHolder].sub(1);
  // ownedTokensCount[_tokenHolder] = ownedTokensCount[_tokenHolder].sub(commodities[_tokenId].value);

  //   emit Burnt(_tokenHolder, _tokenId);

  //   return true;
  // }


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
    //require(_owns(_to, _tokenId), "Only a commodity owner can use 'callRecipient'");
    address recipientImplementation = interfaceAddr(_to, "ICommodityRecipient");
    if (recipientImplementation != 0) {
      ICommodityRecipient(recipientImplementation).commodityReceived(
        _operator,
        _from,
        _to,
        _tokenId,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support this commodity");
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
    // require(
    //   _approvedFor(_operator, _tokenId),
    //   "Only an approved address can use 'callOperator'"
    // ); //todo is this needed? Seems weird to require owner + authorized
    // require(ownerOf(_tokenId) == msg.sender, "Only the owner can use 'callOperator'");
    address recipientImplementation = interfaceAddr(_to, "ICommodityOperator");
    if (recipientImplementation != 0) {
      ICommodityOperator(recipientImplementation).madeOperatorForCommodity(
        _operator,
        _from,
        _to,
        _tokenId,
        _value,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support being an operator of this commodity");
    }
  }

  /// @notice If the recipient address (_to/_operator param) is listed in the registry as supporting
  ///   the ICommodityOperator interface, it calls the revokedOperatorForCommodity
  ///   function.
  /// @param _operator The _operator being revoked
  /// @param _from the owner of the commodity
  /// @param _to the operator address to introspect for ICommodityOperator interface support
  /// @param _tokenId the commodity index
  /// @param _value the value of the commodity to revoke allowance for. This is currently unfinished.
  /// @param _userData the data to pass on behalf of the user. This is currently unsupported.
  /// @param _operatorData the data to pass on behalf of the operator. This is currently unsupported.
  /// @param _preventLocking used to prevent sending to contract addresses who are not supported by this commodity
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
      _approvedFor(_operator, _tokenId),
      "Only an approved address can use 'callRevokedOperator'"
    ); //todo is this needed? Seems weird to require owner + authorized
    require(ownerOf(_tokenId) == msg.sender, "Only an owner of this commodity can use 'callRevokedOperator'");
    address recipientImplementation = interfaceAddr(_to, "ICommodityOperator");
    if (recipientImplementation != 0) {
      ICommodityOperator(recipientImplementation).revokedOperatorForCommodity(
        _operator,
        _from,
        _to,
        _tokenId,
        _value,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support revocation of this commodity");
    }
  }

  function callSender(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) internal {
    require(_approvedFor(_operator, _tokenId), "Only an approved address can use 'callSender'");
    address recipientImplementation = interfaceAddr(_to, "ICommoditySender");
    if (recipientImplementation != 0) {
      ICommoditySender(recipientImplementation).commodityToSend(
        _operator,
        _from,
        _to,
        _tokenId,
        _userData,
        _operatorData
      );
    } else if (_preventLocking) {
      require(isRegularAddress(_to), "The recipient contract does not support sending of commodities");
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
    // TODO (jaycen) PRELAUNCH do we need an operator AND sender caller? Refer to latest erc721 --
    callSender(
      _operator,
      _from,
      _to,
      _tokenId,
      _userData,
      _operatorData,
      false
    );

    require(_to != address(0), "You can not send to the burn address (0x0)");              // forbid sending to 0x0 (=burning)
    require(_tokenId >= 0, "You can only send a valid commodity (>=0)");                  // only send positive amounts
    // require(
    //   _approvedFor(msg.sender, _tokenId) || _owns(_from, _tokenId),
    //   "Only an approved operator can send this commodity"
    // ); // ensure sender owns that token

    safeTransferFrom(_from, _to, _tokenId);
    //_transfer(_from, _to, _tokenId); // todo make a local func called transfer that uses this?
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

  // /// @notice Returns the address currently assigned ownership of a given Commodity.
  // function ownerOf(uint256 _tokenId) public view returns (address owner) {
  //   owner = commodityIndexToOwner[_tokenId];

  //   require(owner != address(0), "The owner cannot be the 0 address");
  // }

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
    // require(
    //   !_owns(msg.sender, _tokenId) && _approvedFor(msg.sender, _tokenId), //todo: do we want to allow an owner to operatorSend?
    //   "Only an approved operator can send the commodity on the owner's behalf"
    // );
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
    //_transfer(_from, _to, _tokenId); // todo make a local func called transfer that uses this?
  }
  //todo do we need this? its not an official standard func
  /// @notice Transfers a commodity to another address. If transferring to a smart
  /// contract be VERY CAREFUL to ensure that it is aware of ERC-721 .
  /// @param _to The address of the recipient, can be a user or contract.
  /// @param _tokenId The ID of the commodity to transfer.
  function transfer(address _to, uint256 _tokenId) public {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0), "You cannot transfer to the burn address");
    require(_tokenId >= 0, "You can only transfer a valid commodity ID (>=0)");
    // You can only send your own commodity
    //require(_owns(msg.sender, _tokenId), "Only the owner of a commodity can use the 'transfer' function");

    // Reassign ownership, clear pending approvals, emit Transfer event.
    safeTransferFrom(msg.sender, _to, _tokenId);
    //_transfer((msg.sender, _to, _tokenId); // todo make a local func called transfer that uses this?

  }

  // /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
  // ///  approval. Setting _approved to address(0) clears all transfer approval.
  // ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
  // ///  _approve() and transferFrom() are used together for putting commodities on auction, and
  // ///  there is no value in spamming the log with Approval events in that case.
  // function _approve(uint256 _tokenId, address _operator) private {
  //   _cumulativeAllowance[_operator] = _cumulativeAllowance[_operator].add(commodities[_tokenId].value);
  //   commodityBundleIndexToApproved[_tokenId] = _operator;
  //   commodityOperatorBundleApprovals[_operator][msg.sender].push(_tokenId);
  // }
  // todo (jaycen): investigate how we enforce consuming this as an alternative to authorizeOperator.
  // it currently exists is to allow for 777 and 721 compatible. It is consumed in the lifecycle
  // of authorizeOperator when listing crcs for sale. Perhaps we can enforce this as an alternative
  // which does not use erc820, and instead is just used for authorizing third party managers
  // of crcs
  /// @notice Grant another address the right to transfer a specific crc via
  ///  transferFrom(). This is the preferred flow for transferring NFTs to contracts.
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the crc that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  // function approve(address _to, uint256 _tokenId) public {
  //   // Only an owner can grant transfer approval.
  //   //require(_owns(msg.sender, _tokenId), "Only the owner of a commodity can approve another address");
  //   // Register the approval (replacing any previous approval).
  //   _approve(_tokenId, _to);
  //   emit Approval(msg.sender, _to, _tokenId);
  // }

  //TODO (jaycen) PRELAUNCH fix/remove this (if we need it for compatibility reasons  -- disabling for now)
  /** @notice Authorize a third party '_operator' to manage (send) 'msg.sender''s tokens. */
  // function authorizeOperator(address) public pure {
  //   revert();
  // }

  // // todo(jaycen): we probably want a variation of this function which
  // // only authorizes a specified value of a bundle, and not the entire thing
  // /// @notice Grant another address the right to transfer a specific crc.
  // /// @param _operator The address of a third party operator who can manage this commodity id
  // /// @param _tokenId the commodity id of which you want to give a third part operator transfer
  // ///   permissions for
  // /// @dev This is the function used to create a sale in a market contract.
  // ///  In combination with ERC820, it dials a contract address, and if it is
  // /// listed as the market contract, creates a sale in the context of that contract.
  // /// Note: it can also be used to authorize any third party as a sender of the bundle.
  // function authorizeOperator(address _operator, uint256 _tokenId, bytes _data) public {
  //   //require(_unlocked(_tokenId), "You cannot authorize an operator for a locked commodity");
  //   require(_operator != msg.sender, "You cannot authorize yourself as an operator");
  //   approve(_operator, _tokenId);
  //   //todo figure out the best approach for all of these preventLocking calls
  //   //todo jaycen probably dont need to pass tokenId anymore, would also be good to find a way to pass the commodity struct itself (currently trying such throws a static memory solidity error :( ))
  //   callOperator(
  //     _operator,
  //     msg.sender,
  //     _operator,
  //     _tokenId,
  //     commodities[_tokenId].value, //todo allow for fractional values to be passed by using the split function
  //     _data,
  //     "",
  //     false
  //   );
  //   emit AuthorizedOperator(_operator, msg.sender);
  // }

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

  /** @notice Revoke a third party '_operator''s rights to manage (send) 'msg.sender''s tokens. */
  function revokeOperator(address _operator, uint256 _tokenId) public {
    //todo jaycen call operator to cancel sale on markets
    require(_operator != msg.sender, "You cannot revoke yourself as an operator");
    //require(_owns(msg.sender, _tokenId), "Only the owner of the commodity can revoke an operator");
    //mAuthorized[_operator][msg.sender] = false; //todo what is this
    callRevokedOperator(
      _operator,
      msg.sender,
      _operator,
      _tokenId,
      commodities[_tokenId].value, //todo allow for fractional values to be passed by using the split function
      "",
      "",
      false
    );
    address operator = commodityBundleIndexToApproved[_tokenId];
    for(uint i = 0; i < commodityOperatorBundleApprovals[operator][msg.sender].length; i++){
      if(commodityOperatorBundleApprovals[operator][msg.sender][i] == _tokenId){
        _cumulativeAllowance[operator] = _cumulativeAllowance[operator].sub(commodities[_tokenId].value);
        delete commodityOperatorBundleApprovals[operator][msg.sender][i];
      }
    }
    delete commodityBundleIndexToApproved[_tokenId];
    emit RevokedOperator(_operator, msg.sender);
  }

  // TODO jaycen PRELAUNCH do we need this for backward compatibility/third party compatibility (erc20) reasons?
  // also do we need it in addition to approvedFor? Both exist as a result of combining 777 + 721
  /** @notice Check whether '_operator' is allowed to manage the tokens held by '_tokenHolder'. */
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
  }

  /** @notice Check whether '_operator' is allowed to manage the tokens held by '_tokenHolder'. */
  function isOperatorForOne(address _operator, uint256 _tokenId) public view returns (bool) {
    return _approvedFor(_operator, _tokenId);
  }

  //TODO (jaycen) PRELAUNCH fix/remove this (if we need it for compatibility reasons  -- disabling for now)
  /** @notice Send '_value' amount of tokens from the address '_from' to the address '_to'. */
  function operatorSend(
    address,
    address,
    uint256,
    bytes,
    bytes
  ) public {
    revert("This is a deprecated function");
  }

  /** @notice Send '_value' amount of tokens from the address '_from' to the address '_to'. */
  function operatorSendOne(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _userData,
    bytes _operatorData
  ) public {
    require(isOperatorForOne(msg.sender, _tokenId), "Only an operator can 'operatorSend' a commodity bundle");
    doSend(
      _from,
      _to,
      _tokenId,
      _userData,
      msg.sender,
      _operatorData,
      false
    );
  }

  //todo fix this
  function minter(address to) public {
    uint256 tokenId = totalSupply();
    mint(to, tokenId);
  }

  // //todo is this kosher with latest standard? Also remove crc specific stuff
  // /// @notice Generates `_value` tokens to be assigned to `_tokenHolder`
  // /// @param _operatorData Data that will be passed to the recipient as a first transfer
  // function mint(
  //   address _to,
  //   bytes _operatorData,
  //   uint256 _value,
  //   bytes _misc
  // ) public returns(uint64) {

  //   /// NOTE: do NOT use timeRegistered for any kind of verification
  //   /// it should only be used to keep a "soft" record for mint time
  //   /// ref: https://ethereum.stackexchange.com/a/9752
  //   CommodityLib.Commodity memory _commodity = CommodityLib.Commodity({
  //       category: uint64(1),
  //       timeRegistered: uint64(now), // solium-disable-line
  //       parentId: 0,
  //       value: uint256(_value),
  //       locked: false,
  //       misc: bytes(_misc)
  //   });
  //   uint _tokenId = commodities.push(_commodity).sub(1);
  //   require(_tokenId <= 18446744073709551616, "You can only mint a commodity in a valid index range");

  //   //TODO: make sure this is ok in production (maybe move to a diff func that invokes callrecipient internally)

  //   safeTransferFrom(address(0), _to, _tokenId);
  //   //_transfer(0, _to, newCRCId); // todo make a local func called transfer that uses this?
  //   callRecipient(
  //     msg.sender,
  //     0x0,
  //     _to,
  //     _tokenId,
  //     "",
  //     _operatorData,
  //     false
  //   );

  //   emit Minted(
  //     _to,
  //     _tokenId,
  //     _value,
  //     msg.sender,
  //     _operatorData
  //   );
  //   return uint64(_tokenId);
  // }
}
