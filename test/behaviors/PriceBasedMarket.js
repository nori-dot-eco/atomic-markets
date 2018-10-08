const abi = require('ethereumjs-abi');

const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const PriceBasedMarketplace = artifacts.require('PriceBasedMarketplace');
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

let priceBasedMarket, nft, token, buyer, seller, admin;
const testPriceBasedSaleBehavior = () => {
  contract(`PriceBasedMarket`, () => {
    beforeEach(async () => {
      ({ buyer0: buyer, seller0: seller, admin0: admin } = getNamedAccounts(
        web3
      ));
      token = await ExampleAdvancedToken.new('Token', 'sym', 1);
      nft = await ExampleNFT.new('NFT', 'nft');
      priceBasedMarket = await PriceBasedMarketplace.new(
        nft.address,
        token.address,
        10
      );
      await token.mint(buyer, web3.toWei('100'), '');
      await nft.mintWithoutId(seller);
    });

    context('Create a NFT sale using approveAndCall', () => {
      describe('ExampleNFT.approveAndCall', () => {
        it('should create an NFT sale, effectively listing in the market', async () => {
          await nft.approveAndCall(
            priceBasedMarket.address,
            0,
            sell(seller, 0, web3.toWei('100')),
            {
              from: seller,
            }
          );
          const nftOwner = await nft.ownerOf(0);
          assert.equal(nftOwner, seller);
        });
      });
    });

    context('Create a NFT sale and then buy using tokens', () => {
      beforeEach(async () => {
        await nft.approveAndCall(
          priceBasedMarket.address,
          0,
          sell(seller, 0, web3.toWei('100')),
          {
            from: seller,
          }
        );
      });
      describe('ExampleNFT.getAllApprovedFor', () => {
        it('should get the ids of every NFT for sale', async () => {
          const nftsForSale = await nft.getAllApprovedFor.call(
            priceBasedMarket.address
          );
          assert.equal(
            nftsForSale[0],
            web3.toWei(0),
            'Market does not have the sale listings for the NFT contract'
          );
        });
      });
      describe('ExampleAdvancedToken.approveAndCall', () => {
        it('should purchase the NFT for sale', async () => {
          let nftOwner = await nft.ownerOf(0);
          let marketOwnerBalance = await token.balanceOf(admin);
          let buyerTokenBalance = await token.balanceOf(buyer);
          let sellerTokenBalance = await token.balanceOf(seller);
          assert.equal(
            buyerTokenBalance,
            web3.toWei('100'),
            'buyer does not have enough tokens to buy the NFT'
          );
          assert.equal(sellerTokenBalance, 0, 'seller already has tokens');
          assert.equal(
            marketOwnerBalance,
            0,
            'The market operator already has a balance'
          );
          assert.equal(nftOwner, seller);
          await token.approveAndCall(
            priceBasedMarket.address,
            web3.toWei('100'),
            buy(buyer, 0, web3.toWei('100')),
            {
              from: buyer,
            }
          );
          nftOwner = await nft.ownerOf(0);
          buyerTokenBalance = await token.balanceOf(buyer);
          sellerTokenBalance = await token.balanceOf(seller);
          marketOwnerBalance = await token.balanceOf(admin);
          assert.equal(
            marketOwnerBalance,
            web3.toWei('10'),
            'the market owner did not receive their profit'
          );
          assert.equal(
            buyerTokenBalance.toString(),
            0,
            'buyer did not spend the tokens'
          );
          assert.equal(
            sellerTokenBalance.toString(),
            web3.toWei('90'),
            'seller did not receive the tokens'
          );
          assert.equal(nftOwner, buyer, 'The buyer does not own the NFT');
        });
      });
      describe('ExampleAdvancedToken.clearApprovalAndCall', () => {
        it('should cancel a NFT sale after having listed it', async () => {
          let nftOwner = await nft.ownerOf(0);
          let salePrice = await priceBasedMarket.getSalePrice(0);
          let approved = await nft.getApproved(0);
          assert.equal(
            approved,
            priceBasedMarket.address,
            'The market does not have approval'
          );
          assert.equal(
            salePrice,
            web3.toWei('100'),
            'The NFT did not list for sale'
          );
          assert.equal(
            nftOwner,
            seller,
            'The seller does not own the NFT before canceling the sale'
          );
          await nft.clearApprovalAndCall(0, { from: seller });
          nftOwner = await nft.ownerOf(0);
          salePrice = await priceBasedMarket.getSalePrice(0);
          assert.equal(salePrice, 0, 'The NFT is still for sale');
          approved = await nft.getApproved(0);
          assert.equal(
            approved,
            '0x0000000000000000000000000000000000000000',
            'The market still has approval'
          );
          assert.equal(nftOwner, seller, 'The buyer does not own the NFT');
        });
      });
    });
  });
};

module.exports = {
  testPriceBasedSaleBehavior,
};
