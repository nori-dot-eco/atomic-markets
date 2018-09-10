const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const PriceBasedMarketplace = artifacts.require('PriceBasedMarketplace');

module.exports = (deployer, network, accounts) => {
  deployer.then(async () => {
    const token = await deployer.deploy(
      ExampleAdvancedToken,
      'Token',
      'sym',
      1
    );
    const nft = await deployer.deploy(ExampleNFT, 'NFT', 'nft', accounts[0]);
    await deployer.deploy(
      PriceBasedMarketplace,
      nft.address,
      token.address,
      accounts[0]
    );
  });
};
