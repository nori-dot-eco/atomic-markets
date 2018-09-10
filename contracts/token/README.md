# NORI token

This is the contract which represents the ERC777 token to be exchanged for NFTs within the market.

## Background

More info on ERC-777 tokens can be found here:

- [ERC-777 Advanced Token Standard](https://eips.ethereum.org/EIPS/eip-777).

## Purpose

The token is used to purchase NFTs

## Key features

Since the token uses the ERC 777 standard it can be used in several fancy ways:

- contract introspection via [ERC-820](https://github.com/ethereum/EIPs/issues/820)

This feature allows us to register which contracts support which interfaces. As such, when you send a token to an address, you can lookup whether the receiving address supports the interface that function is trying to consume. If it does, it can "dial out" to the receiving address and have it execute a function from within its context (note this changes `msg.sender` from the tx sender to the token contract itself, so the receiving address things it was the token contract, and not the token owner, who is executing this "dialed" function).

Additionally you can use this to prevent tokens being sent to unknown addresses, or just decline token sending in certain scenarios.

An example of this being consumed is in the `authorizeOperator` function which in turn calls the `callOperator` function which in turn dials the `madeOperatorForTokens` function in the market contracts, which in turn calls the `buy` function in the market to initate a CRC purchase.

Currently, it is through this key feature that we are "atomically swapping" one token for one NFT in the marketplace.

- you can pass encoded data to the `send` function and then to consume the token in a similar way that ether is consumed.

This is an extremely powerful way to think about transactions of tokens. For example, if I had a function in a contract called `FuturesExchange.sol` which has a function called `swapTokenForNFT`, then rather than creating an introspection call, or depositing the token into the FuturesExchange so that you can then invoke a second function to swap it, you would instead just:

`data = encodeCall(...data for swapTokenForNFT)`

`token.send(... data)`

Or, you could use it in to create a sale in some future alternative market:

```javascript
const createSale = (id, from, value) =>
  encodeCall(
    'createSale',
    ['uint256', 'uint64', 'uint32', 'address', 'uint256', 'bytes'],
    [id, 1, 2, from, value, '']
  );

// ...

await nft.approveAndCall(
  fioTokenizedCommodityMarket.address,
  100,
  0,
  createSale(0, getNamedAccounts(web3).seller0, 100),
  {
    from: getNamedAccounts(web3).seller0,
  }
);
```

and then in the market:

```solidity
function madeOperatorForNFT(
  address, // operator,
  address, // from,
  address, // to,
  uint, // tokenId,
  uint256, // value,
  bytes, // userData,
  bytes operatorData
) public {
  if (preventNFTOperator) {
    revert();
  }
  //shazam here:
  require(_executeCall(address(this), 0, operatorData));
}

function _executeCall(address to, uint256 value, bytes data) private returns (bool success) {
  assembly { // solium-disable-line security/no-inline-assembly
    success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
  }
}
```

Futher notes on implementations of this can be found here:

- https://github.com/nori-dot-eco/contracts/pull/57/commits/b2db4287b074d8ebc70b3898050cc818ad679683
- https://github.com/nori-dot-eco/contracts/pull/57/commits/22411d6e4bf2c81ee325e07320b6eac8c8bf2d0c
- https://github.com/nori-dot-eco/contracts/pull/57
