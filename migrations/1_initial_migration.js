const Treasury = artifacts.require("Treasury");
const Marketplace = artifacts.require("Marketplace");

module.exports = function (deployer) {
  deployer.deploy(Treasury);
  deployer.deploy(Marketplace);
};
