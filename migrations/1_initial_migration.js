const Migrations = artifacts.require("Migrations");
const TestToken = artifacts.require("test/TestToken");
const Treasury = artifacts.require("Treasury");
const Marketplace = artifacts.require("Marketplace");
const TestNFT = artifacts.require("test/TestNFT");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(TestToken);
  deployer.deploy(Treasury);
  deployer.deploy(Marketplace);
  deployer.deploy(TestNFT);
};
