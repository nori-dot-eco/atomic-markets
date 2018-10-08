pragma solidity ^0.4.24;

import "./AdvancedERC721.sol";
import "./ERC721Operator.sol";
import "../../node_modules/eip820/contracts/ERC820Implementer.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol";


/// @title  AdvancedERC721Base: a fully backward compatible extension to the ERC721 interfaces to be more
/// closely consumable to the example of invoking call data upon approving allowances to operators
/// akin to the implementation inside the example ERC 777 token extensions in this repository.
/// Note: for simplicity of the example of these atomic market contracts, I have RAdvancedERC721Base
/// callSender, operatorSend, send, callRecipient etc functions (defined in ERC 777 and ERC 820).
/// In a live implementation you should probably prefer to use those instead.
contract AdvancedERC721Base is ERC721Mintable, ERC721Pausable, ERC820Implementer, AdvancedERC721 {

  using SafeMath for uint256;

  constructor(
    string _name,
    string _symbol
  ) public ERC721Full(_name, _symbol) {
    erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
    setInterfaceImplementation("ERC721", this);
    setInterfaceImplementation("AdvancedERC721", this);
  }

  // Note: for the sake of simplicity for this example, we will use the ERC 777/ ERC 820
  // recipient calling functionality. Since we need to use the 777 token anyways,
  // and for the purpose of atomic markets all we care about is the operator/spender/allowance
  // functions, we will only add this function to work in a way that is pretty much identical
  // to the way it works in the ERC 777 example token
  /// @notice approves another address the specified allowance and passes the recipient data which
  /// can be used for execution
  function approveAndCall(address _operator, uint256 _tokenId, bytes _data) external {
    approve(_operator, _tokenId);
    callOperator(
      _operator,
      msg.sender, // note: this MUST always be msg.sender
      _operator,
      _tokenId,
      0, // this will be used in a future version
      _data,
      "",
      false
    );
  }

  /** @notice Revoke a third party '_operator''s rights to manage (send) 'msg.sender''s tokens. */
  function clearApprovalAndCall(uint256 _tokenId) external {
    address owner = ownerOf(_tokenId);
    require(msg.sender == owner, "Only the owner of the NFT can revoke approval");

    address operator = getApproved(_tokenId);
    _clearApproval(owner, _tokenId);
    callRevokedOperator(
      operator,
      msg.sender,
      operator,
      _tokenId,
      0,
      "",
      "",
      false
    );
  }

  /// @dev Mints a new NFT assigning it an id equal to the latest index
  function mintWithoutId(address _to) public onlyMinter {
    uint256 tokenId = totalSupply();
    mint(_to, tokenId);
  }

  /// @notice Calls the operator and passes it data if it supports the ERC721Operator interface
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
    require(ownerOf(_tokenId) == msg.sender, "Only the owner of the NFT can use 'callOperator'");
    address recipientImplementation = interfaceAddr(_to, "ERC721Operator");
    if (recipientImplementation != 0) {
      ERC721Operator(recipientImplementation).madeOperatorForNFT(
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

  /// @notice If the recipient address (_to/_operator param) is listed in the registry as supporting
  ///   the ERC721Operator interface, it calls the revokedOperatorForNFT
  ///   function.
  /// @param _operator The _operator being revoked
  /// @param _from the owner of the NFT
  /// @param _to the operator address to introspect for ERC721Operator interface support
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
      "Only an approved address of this NFT can use 'callRevokedOperator'"
    );
    address recipientImplementation = interfaceAddr(_to, "ERC721Operator");
    if (recipientImplementation != 0) {
      ERC721Operator(recipientImplementation).revokedOperatorForNFT(
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
    require(getApproved(_tokenId) != _operator, "The operator was not revoked");
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

  /** @notice helper function to get all of the NFTs an address is approved for */
  function getAllApprovedFor(address _operator) public returns(uint256[]) {
    uint256[] storage approvals;
    for (uint256 i = 0; i < totalSupply(); i++ ) {
      if(getApproved(i) == _operator){
        approvals.push(i);
      }
    }
    return approvals;
  }

}