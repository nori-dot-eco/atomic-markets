# NFT (ERC-721) Contracts

These are the base contracts for the ERC 721 NFTs. They have been extended to be more compatible with ERC777 so that they can be used for atomic swaps

## Background and Related works

More implementation notes, including those used at Nori can be found here:

- [Commodity Interface Standard](https://github.com/nori-dot-eco/NIPs/blob/NIP-4-Commodity-Interface-Standard/NIP-4-Commodity-Interface-Standard.md)
- [CommodityType](https://github.com/nori-dot-eco/NIPs/blob/NIP-5-CommodityType/NIP-5-CommodityType.md)

The Nori commodity smart contracts are a mash up of the [ERC-777 advanced token standard](https://eips.ethereum.org/EIPS/eip-777) and the [ERC-721 non-fungible token standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md).

Each commodity token maintains distinguishable non-fungible attributes that differ each bundle from one another. However, they also contain a fungible quality which keeps track of the total amount of CRCs in each "bundle". As such, a commodity can be thought of as a bundle of fungible tokens where the entire bunle is linked to a particular source that contains a number of descriptive attributes. This "bundling" is the key distinction between this and ERC 721. Unlike ERC721 where each token is singular and non fungible, the commodity is a representation of bundles of non fungible tokens that can be split to create two new bundles equal to the original value of the bundle.
