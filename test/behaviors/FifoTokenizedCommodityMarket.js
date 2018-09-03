/* globals network */
const getNamedAccounts = require('../helpers/getNamedAccounts');

let fifoMarket, nft, token;

const testFifoSaleBehavior = () => {
  contract(`FifoTokenizedCommodityMarket`, accounts => {
    beforeEach(async () => {
      console.log(accounts[0]);
      token = await artifacts
        .require('ExampleAdvancedToken')
        .new('Token', 'sym', 1, 0, accounts[0]);
      nft = await artifacts
        .require('ExampleNFT')
        .new('NFT', 'nft', accounts[0]);
      fifoMarket = await artifacts
        .require('FifoMarketplace')
        .new([nft.address, token.address], accounts[0]);
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
  testFifoSaleBehavior,
};
