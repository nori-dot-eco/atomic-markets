import FifoMarketplaceTests from './FifoMarketplace.test';
import SelectableMarketplaceTests from './SelectableMarketplace.test';

const {
  admin0,
  admin1,
  seller0,
  seller1,
  buyer0,
  buyer1,
  unregistered0,
  unregistered1,
  unregistered2,
  unregistered3,
} = require('./helpers/getNamedAccounts')(web3);

context('Setup test environment', () => {
  before(() => {
    // eslint-disable-next-line no-console
    console.info(`
      Tests have been set up with:
      admin0: ${admin0}
      admin1: ${admin1}
      seller0: ${seller0}
      seller1: ${seller1}
      buyer0: ${buyer0}
      buyer1: ${buyer1}
      unregistered0: ${unregistered0}
      unregistered1: ${unregistered1}
      unregistered2: ${unregistered2}
      unregistered3: ${unregistered3}
    `);
  });

  context('Execute tests', () => {
    // SelectableMarketplaceTests();
    FifoMarketplaceTests();
  });
});
