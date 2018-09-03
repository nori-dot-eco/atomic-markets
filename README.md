Todo:

- make sure web31 dependency inside eip820 submodule doesn't interfere with web3 < 1 in root
- install directions (including for submodule)

# Atomic Swap Marketplaces

The smart contracts contained herein will allow you to create a marketplace for the swapping of Ethereum non-fungible tokens(NFT) and advanced tokens.

## Market Contracts

### Background

There are multiple types of markets:

- Selectable: a market where buyers and sellers can choose which NFT they want to purchase with their tokens.
- FIFO: a market where NFTs are bought and sold in a first-in-first-out queue (similar to a spot market). In this market, buyers do not get to choose which NFTs they are purchasing.

### Purpose

The Market contracts are used to buy and sell NFTs using tokens. They are the contracts by which sellers list NFTs and buyers purchase them with tokens.

The Market contracts are designed to never take custody of buyer or seller assets. Instead, they are a medium that is used to swap a NFT asset from a seller's own account to a buyer's account without ever taking custody of the seller's asset itself (nor the buyer's tokens).

At a high-level, the market accomplishes this form of an atomic swap by use of the (modified) ERC 721 and ERC 777 advanced token's `authorizeOperator` function. When a seller invokes this function, passing in the market address as the intended operator, the market is given authorization to transfer the NFT on behalf of the user as soon as the market receives a corresponding token authorization from a buyer. When it does receive this corresponding authorization (done in the same way as the NFT was done-- using the token's `authorizeOperator` function), the Market automatically invokes (via contract introspection described in EIP820) an `operatorSendOne` call on the NFT and an `operatorSend` call on the token to send the NORI to the supplier, and the CRC to the buyer.

Basically, the market "listens" for sellers who say "I want to sell this NFT", and "listens" for buyers who say "I want to buy some NFTs with my tokens", and when it can match these two conversations, it automatically swaps the token for the NFT.

**In other words, you never have to deposit the tokens or the NFTs in an exchange.**

### Key features

- An atomic swap medium used to swap tokens for NFTs
- a medium for querying the amount of NFTss for sale
