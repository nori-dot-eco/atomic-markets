/* globals network */
const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const SelectableMarketplace = artifacts.require('SelectableMarketplace');
const getNamedAccounts = require('../helpers/getNamedAccounts');

let selectableMarket, nft, token, admin, buyer, seller;

const testSelectableSaleBehavior = () => {
  contract(`FifoTokenizedCommodityMarket`, () => {
    beforeEach(async () => {
      ({ buyer0: buyer, seller0: seller, admin0: admin } = getNamedAccounts(
        web3
      ));
      token = await ExampleAdvancedToken.deployed();
      nft = await ExampleNFT.deployed();
      selectableMarket = await SelectableMarketplace.deployed();
      await token.mint(buyer, web3.toWei('100'), '');
      await nft.mint(seller, '', web3.toWei('100'), '');
    });

    context('Create a NFT sale using authorizeOperator', () => {
      describe('ExampleNFT.authorizeOperator', () => {
        it('should create an NFT sale listing in the market', async () => {
          await nft.authorizeOperator(selectableMarket.address, 0, '100', {
            from: seller,
          });
        });
      });
    });

    context('Create a NFT sale and then buy using tokens', () => {
      beforeEach(async () => {
        await nft.authorizeOperator(
          selectableMarket.address,
          0,
          web3.fromAscii(web3.toWei('100')),
          {
            from: seller,
          }
        );
      });
      describe('ExampleAdvancedToken.authorizeOperator', () => {
        it('should purchase the NFT for sale', async () => {
          let nftOwner = await nft.ownerOf(0);
          assert.equal(nftOwner, seller);
          await token.authorizeOperator(
            selectableMarket.address,
            web3.toWei('100'),
            {
              from: buyer,
            }
          );
          nftOwner = await nft.ownerOf(0);
          assert.equal(nftOwner, buyer);
        });
      });
    });
  });
};

module.exports = {
  testSelectableSaleBehavior,
};
