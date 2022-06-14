const Migrations = artifacts.require("Migrations");
const TestToken = artifacts.require("test/TestToken");
const Treasury = artifacts.require("Treasury");
const Marketplace = artifacts.require("Marketplace");
const TestNFT = artifacts.require("test/TestNFT");

const truffleAssert = require("truffle-assertions");
const web3 = require("web3");

contract("Migrations", ([deployer, account1, ...accounts]) => {
    it("should get the correct deployer", async() => {
        const migrationsInstance = await Migrations.deployed();
        const getOwner = await migrationsInstance.owner.call();
        expect(getOwner).to.equal(deployer);
    });

    it("should allow to modify the last completed migration", async() => {
        const migrationsInstance = await Migrations.deployed();
        let getLastCompletedMigration = await migrationsInstance.last_completed_migration.call();

        // @dev Checks the default value of Migrations.sol
        expect(true).to.equal(getLastCompletedMigration.eq(web3.utils.toBN(1)));

        // @dev update last_completed_migration = 2
        await migrationsInstance.setCompleted(web3.utils.toBN(2), {from: deployer});
        getLastCompletedMigration = await migrationsInstance.last_completed_migration.call();
        expect(true).to.equal(getLastCompletedMigration.eq(web3.utils.toBN(2)));
    });

    it("should fail to modify the last completed migration", async() => {
        const migrationsInstance = await Migrations.deployed();

        await truffleAssert.fails(
            migrationsInstance.setCompleted(
                web3.utils.toBN(2), {from: account1}
            ),
            "Ownable: caller is not the owner"
        );
    });
});

contract("Treasury and TestToken", ([deployer, account1, ...accounts]) => {
    it("should return 1_000_000 ether minted back to deployer.", async() => {
        const testTokenInstance = await TestToken.deployed();
        const balanceOf = await testTokenInstance.balanceOf(deployer);
        expect(true).to.equal(balanceOf.eq(web3.utils.toWei(web3.utils.toBN(1_000_000), "ether")));
    });

    it("should transfer 100 wei to treasury contract", async() => {
        const testTokenInstance = await TestToken.deployed();
        const treasuryInstance = await Treasury.deployed();
        
        // @dev treasury balance of TToken = 0 wei
        let treasuryBalance = await testTokenInstance.balanceOf(treasuryInstance.address);
        expect(true).to.equal(treasuryBalance.eq(web3.utils.toBN(0)));

        // @dev approve TToken and transfer to Treasury contract
        await testTokenInstance.approve(deployer, web3.utils.toBN(100), {from: deployer});
        await testTokenInstance.transferFrom(deployer, treasuryInstance.address, web3.utils.toBN(100), {from: deployer});

        // @dev treasury balance of TToken = 100 wei
        treasuryBalance = await testTokenInstance.balanceOf(treasuryInstance.address);
        expect(true).to.equal(treasuryBalance.eq(web3.utils.toBN(100)));
    });

    it("should remove 25 wei from removeFunds", async() => {
        const testTokenInstance = await TestToken.deployed();
        const treasuryInstance = await Treasury.deployed();

        await treasuryInstance.removeFunds(testTokenInstance.address, web3.utils.toBN(25), {from: deployer});
        const treasuryBalance = await testTokenInstance.balanceOf(treasuryInstance.address);
        expect(true).to.equal(treasuryBalance.eq(web3.utils.toBN(75)));
    });

    it("should fail if you try to remove funds from non-deployer address", async() => {
        const testTokenInstance = await TestToken.deployed();
        const treasuryInstance = await Treasury.deployed();

        await truffleAssert.fails(
            treasuryInstance.removeFunds(
                testTokenInstance.address,
                web3.utils.toBN(1), 
                {from: account1}
            ),
            "Ownable: caller is not the owner"
        );
    });
});

contract("Marketplace", async([deployer, account1, ...acounts]) => {
    it("should list the NFT on the marketplace", async() => {
        const marketplaceInstance = await Marketplace.deployed();
        const testNFTInstance = await TestNFT.deployed();

        await testNFTInstance.approve(marketplaceInstance.address, web3.utils.toBN(1), {from: deployer});
        const deployerNftBalance = await testNFTInstance.balanceOf(deployer);
        expect(true).to.equal(deployerNftBalance.eq(web3.utils.toBN(1)));

        await marketplaceInstance.listNft(
            testNFTInstance.address, 
            web3.utils.toBN(1), 
            web3.utils.toWei(web3.utils.toBN(100), "ether")
        );


    });
});
