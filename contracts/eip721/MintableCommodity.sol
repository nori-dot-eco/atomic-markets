// pragma solidity ^0.4.24;
// import "./CommodityLib.sol";
// import "./IMintableCommodity.sol";
// import "./BasicCommodity.sol";
// import "../../node_modules/zeppelin-solidity/contracts//math/SafeMath.sol";


// contract MintableCommodity is BasicCommodity, IMintableCommodity {
//   using SafeMath for uint256;

//   event Minted(address indexed to, uint commodityId, uint256 amount, address indexed operator, bytes operatorData);
//   event InsufficientPermission(address sender, bytes operatorData, uint256 value, bytes misc);

//   /// @notice Generates `_value` tokens to be assigned to `_tokenHolder`
//   /// @param _operatorData Data that will be passed to the recipient as a first transfer
//   function mint(
//     address _to,
//     bytes _operatorData,
//     uint256 _value,
//     bytes _misc
//   ) public returns(uint64) {

//     /// NOTE: do NOT use timeRegistered for any kind of verification
//     /// it should only be used to keep a "soft" record for mint time
//     /// ref: https://ethereum.stackexchange.com/a/9752
//     CommodityLib.Commodity memory _commodity = CommodityLib.Commodity({
//         category: uint64(1),
//         timeRegistered: uint64(now), // solium-disable-line
//         parentId: 0,
//         value: uint256(_value),
//         locked: false,
//         misc: bytes(_misc)
//     });
//     uint newCRCId = commodities.push(_commodity).sub(1);
//     require(newCRCId <= 18446744073709551616, "You can only mint a commodity in a valid index range");

//     //TODO: make sure this is ok in production (maybe move to a diff func that invokes callrecipient internally)
//     _transfer(0, _to, newCRCId);
//     callRecipient(
//       msg.sender,
//       0x0,
//       _to,
//       newCRCId,
//       "",
//       _operatorData,
//       false
//     );

//     emit Minted(
//       _to,
//       newCRCId,
//       _value,
//       msg.sender,
//       _operatorData
//     );
//     return uint64(newCRCId);
//   }

// }