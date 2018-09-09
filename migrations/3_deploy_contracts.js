const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const SelectableMarketplace = artifacts.require('SelectableMarketplace');
const ConversionUtils = artifacts.require('ConversionUtils');
// todo use getnamed accounts
module.exports = (deployer, network, accounts) => {
  deployer.then(async () => {
    const token = await deployer.deploy(
      ExampleAdvancedToken,
      'Token',
      'sym',
      1
    );
    const nft = await deployer.deploy(ExampleNFT, 'NFT', 'nft', accounts[0]);
    await deployer.deploy(ConversionUtils);
    await deployer.link(ConversionUtils, SelectableMarketplace);
    await deployer.deploy(
      SelectableMarketplace,
      [nft.address, token.address],
      accounts[0]
    );
  });
};
