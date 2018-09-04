require('babel-register')({
  ignore: /node_modules\/(?!zeppelin-solidity)/,
});
require('babel-polyfill');
// const HDWalletProvider = require('truffle-hdwallet-provider');

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    testrpc: {
      host: 'localhost',
      gas: 0xfffffffffff, // <-- Use this high gas-limit value
      gasPrice: 0x01, // <-- Use this low gas price
      port: 8545,
      network_id: '*',
    },
    develop: {
      host: 'localhost',
      gas: 0xfffffffffff, // <-- Use this high gas-limit value
      gasPrice: 0x01, // <-- Use this low gas price
      port: 9545,
      network_id: '*',
    },
  },
  mocha: {
    enableTimeouts: false,
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
