/* globals */
const abi = require('ethereumjs-abi');

const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const SelectableMarketplace = artifacts.require('SelectableMarketplace');
const getNamedAccounts = require('../helpers/getNamedAccounts');

function encodeCall(name, _arguments, values) {
  const methodId = abi.methodID(name, _arguments).toString('hex');
  const params = abi.rawEncode(_arguments, values).toString('hex');
  return `0x${methodId}${params}`;
}

const buy = (from, id, value) =>
  encodeCall('buy', ['address', 'uint256', 'uint256'], [from, id, value]);

const sell = (from, id, value) =>
  encodeCall(
    'createSale',
    ['address', 'uint256', 'uint256'],
    [from, id, value]
  );

let selectableMarket, nft, token, admin, buyer, seller;
// todo rename fie (currently "crc" market)
const testSelectableSaleBehavior = () => {
  contract(`FifoTokenizedCommodityMarket`, () => {
    beforeEach(async () => {
      ({ buyer0: buyer, seller0: seller, admin0: admin } = getNamedAccounts(
        web3
      ));
      token = await ExampleAdvancedToken.new('Token', 'sym', 1);
      nft = await ExampleNFT.new('NFT', 'nft', admin);
      selectableMarket = await SelectableMarketplace.new(
        [nft.address, token.address],
        admin
      );
      await token.mint(buyer, web3.toWei('100'), '');
      await nft.minter(seller);
    });

    context('Create a NFT sale using authorizeOperator', () => {
      describe('ExampleNFT.authorizeOperator', () => {
        it('should create an NFT sale listing in the market', async () => {
          await nft.approveAndCall(
            selectableMarket.address,
            0,
            sell(seller, 0, 100),
            {
              from: seller,
            }
          );
          // todo assert
        });
      });
    });

    context('Create a NFT sale and then buy using tokens', () => {
      beforeEach(async () => {
        await nft.approveAndCall(
          selectableMarket.address,
          0,
          sell(seller, 0, web3.toWei('100')),
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
            buy(buyer, 0, web3.toWei('100')),
            {
              from: buyer,
            }
          );
          nftOwner = await nft.ownerOf(0);
          const buyerTokenBalance = await token.balanceOf(buyer);
          const sellerTokenBalance = await token.balanceOf(seller);
          assert.equal(
            buyerTokenBalance.toString(),
            0,
            'buyer did not spend the tokens'
          );
          assert.equal(
            sellerTokenBalance.toString(),
            web3.toWei('100'),
            'seller did not receive the tokens'
          );
          assert.equal(nftOwner, buyer, 'The buyer does not own the NFT');
        });
      });
    });
  });
};

module.exports = {
  testSelectableSaleBehavior,
};
