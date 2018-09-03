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

    context('Create a sale using authorizeOperator', () => {
      describe('authorizeOperator', () => {
        it('should create an NFT sale listing in the market', async () => {
          await nft.authorizeOperator(selectableMarket.address, 0, '100', {
            from: seller,
          });
        });
      });
    });
  });
};

module.exports = {
  testSelectableSaleBehavior,
};
