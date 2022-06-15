const TestToken = artifacts.require("test/TestToken");
const TestNFT = artifacts.require("test/TestNFT");

/**
 * @dev For testing purpose only and should not be used
 * during deployment stage.
 */
module.exports = function(deployer) {
    deployer.deploy(TestToken);
    deployer.deploy(TestNFT);
}