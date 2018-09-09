pragma solidity ^0.4.24;

library ConversionUtils {
  event Test(uint256 total);
  function bytesToUint(bytes b) public returns (uint256){
    uint256 number;
    for(uint256 i = 0; i < b.length; i++){
      number = number + uint256(b[i])*(2**(8*(b.length-(i+1))));
      emit Test(number);
    }
    return number;
  }
}