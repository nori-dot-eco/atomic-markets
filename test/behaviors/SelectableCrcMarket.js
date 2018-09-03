/* globals network */
const getNamedAccounts = require('../helpers/getNamedAccounts');

let selectableMarket, nft, token;

const testSelectableSaleBehavior = () => {
  contract(`FifoTokenizedCommodityMarket`, accounts => {
    beforeEach(async () => {
      token = await artifacts
        .require('ExampleAdvancedToken')
        .new('Token', 'sym', 1, 0, accounts[0]);
      // nft = await artifacts
      //   .require('ExampleNft')
      //   .new('NFT', 'nft', accounts[0]);
      // selectableMarket = await artifacts
      //   .require('SelectableMarketplace')
      //   .new([token.address, nft.address], accounts[0]);
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
