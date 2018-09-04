module.exports = web3 => {
  const allAccounts = web3.personal.listAccounts;

  const [
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
  ] = allAccounts;

  return {
    allAccounts,
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
  };
};
