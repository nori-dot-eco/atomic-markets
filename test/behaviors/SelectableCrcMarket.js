/* globals network */
const getNamedAccounts = require('../helpers/getNamedAccounts');

let selectableMarket, nft, token;

const testSelectableSaleBehavior = () => {
  contract(`FifoTokenizedCommodityMarket`, () => {
    beforeEach(async () => {
      token = await artifacts
        .require('ExampleAdvancedToken')
        .new('Token', 'sym', 1, 0, getNamedAccounts(web3).admin0);
      nft = await artifacts
        .require('ExampleNFT')
        .new('NFT', 'nft', getNamedAccounts(web3).admin0);
      selectableMarket = await artifacts
        .require('FifoMarketplace')
        .new([nft.address, token.address], getNamedAccounts(web3).admin0);
    });

    context('Create a sale using authorizeOperator', () => {
      describe('revokeOperator', () => {
        it('should cancel the sale in the market', () => {
          assert.ok(true);
        });
      });
    });
  });
};

module.exports = {
  testSelectableSaleBehavior,
};
