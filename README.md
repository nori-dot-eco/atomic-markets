<p align="center">
 <img width="735px" padding-left="100" height="100" alt="box-img-sm-template" src="https://user-images.githubusercontent.com/18407013/45330311-ac0ad100-b519-11e8-824d-700aa9d66aa3.png">
</p>
<p align="center">
<h1 align="center">Everything you need to quickly jump in and begin swapping non-fungible tokens for other tokens</h1>
</p>

---

## Quick Start

<p align="center">
<img src="https://rawgit.com/jaycenhorton/b05682e31f66b3e9130797e9c13d36ee/raw/6f89be5a263f43ef8b48c1dcfd580f7a29717208/atomic-markets.svg">
</p>

```
truffle unbox nori-dot-eco/atomic-markets
```

```
truffle test
```

## Key features

- Boilerplate ERC-721 non-fungible token (NFT) contracts super-powered with some extended atomic logic

- Boilerplate ERC-777 advanced token standard contracts super-powered with some atomic logic

- Market contracts for price-based atomic swaps of NFT assets for token assets

- Bring your own UI. Plug your own UI logic directly into the contracts. If UI examples would be helpful let me know. Keep a look out for an upcoming post on [medium](https://medium.com/@jaycenhorton) where Ill dive a bit deeper in to how exactly to do that

### Prereqs

1. Make sure you are using a unix flavor operating system for everything
2. Install some stuff:
   - [yarn](https://yarnpkg.com/en/)
   - [node 9.1.0](https://nodejs.org/en/) (or better yet, install
     [nvm](https://github.com/creationix/nvm))
   - [truffle](https://truffleframework.com/)

---

## Market Contracts

### Background

### Check out the [latest post on this topic here](https://hackernoon.com/test-bd14e0e1170d)

There are multiple types of markets:
cen

- Price Based: a market where buyers and sellers can choose which NFT they want to purchase with their tokens.

- **WIP** _First-in-first-out (FIFO): a market where NFTs are bought and sold in a first-in-first-out queue (similar to a spot market). In this market, buyers do not get to choose which NFTs they are purchasing._

### Purpose

The Market contracts are used to buy and sell NFTs using tokens. They are the contracts by which sellers list NFTs and buyers purchase them with tokens.

The Market contracts are designed to never take custody of buyer or seller assets. Instead, they are a medium that is used to swap a NFT asset from a seller's own account to a buyer's account without ever taking custody of the seller's asset itself (nor the buyer's tokens).

At a high-level, the market accomplishes this form of an atomic swap by use of the (modified) ERC 721 and ERC 777 advanced token's `approveAndCall` function.

When a seller invokes this function, passing in the market address as the intended operator, the market is given authorization to transfer the NFT on behalf of the user as soon as the market receives a corresponding token authorization from a buyer.

When the market does receive this corresponding authorization (done in the same way as the NFT was done-- using the token's `approveAndCall` function), the Market automatically invokes (via contract introspection described in EIP820) a `safeTransferFrom` call on the NFT AND an `transferFrom` call on the token in the same transaction

The result?

An atomic swap of one asset for the other using a single transaction and without an intermediary custodying the assets.

Basically, the market "listens" for sellers who say "I want to sell this NFT", and "listens" for buyers who say "I want to buy some NFTs with my tokens", and when it can match these two conversations, it automatically swaps the token for the NFT.

**In other words, you never have to deposit the tokens or the NFTs in an exchange.**

## Todo:

#### Documentation

- write notes on how [Nori](Nori.com) uses these types of contracts

- write a note about how it could be extended for updating prices without relisting (might already be possible by re-approving)

- notes on how this box adds partial erc 820 support, but not full extension for 777 support (but that can be done). It also adds only one additional functions to call when authorizing operator, this call matches erc820 rather than the standard erc721 165 support (but should be backward compatible-- Ive chosen to use 820 support to match that of the token's erc777 support so as not be more ubiquitous and hopefully not to be confusing for readers/users)

#### Future

- modify buy/sell to be a generic "create order" so that tokens/nft orders can be added in any order (currently the contracts require creating the NFT sale, and then buying it with a token-- we can instead generalize and just add an order book that checks if there is a matching order upon invoking a function called `createOrder`)
- write implementation for FIFO market (for a preview, you can see an implementation of that logic in the [Nori contracts github repository](https://github.com/nori-dot-eco/contracts/tree/master/contracts/market)
