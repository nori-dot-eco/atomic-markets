const ExampleAdvancedToken = artifacts.require('ExampleAdvancedToken');
const ExampleNFT = artifacts.require('ExampleNFT');
const SelectableMarketplace = artifacts.require('SelectableMarketplace');
// todo use getNamed accounts
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
      SelectableMarketplace,
      [nft.address, token.address],
      accounts[0]
    );
  });
};
