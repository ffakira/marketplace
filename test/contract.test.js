const TestToken = artifacts.require("test/TestToken");
const Treasury = artifacts.require("Treasury");
const Marketplace = artifacts.require("Marketplace");
const TestNFT = artifacts.require("test/TestNFT");

const truffleAssert = require("truffle-assertions");
const web3 = require("web3");

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

        const nftPrice = web3.utils.toBN(10);

        await marketplaceInstance.listNft(
            testNFTInstance.address, 
            web3.utils.toBN(1), 
            web3.utils.toWei(nftPrice, "ether")
        );

        const offer = await marketplaceInstance.listOffers.call(deployer);
        expect(true).to.equal(offer.tokenId.eq(web3.utils.toBN(1)));
        expect(true).to.equal(offer.amount.eq(web3.utils.toWei(nftPrice, "ether")));
        expect(false).to.equal(offer.closeOffer);
        expect(testNFTInstance.address).to.equal(offer.nft);

        const confirmOwnership = await testNFTInstance.ownerOf(web3.utils.toBN(1));
        expect(confirmOwnership).to.equal(marketplaceInstance.address);
    });

    it("should delist the NFT from the marketplace", async() => {
        const marketplaceInstance = await Marketplace.deployed();
        const testNFTInstance = await TestNFT.deployed();

        // @dev Marketplace contains the user's NFT
        let marketplaceBalance = await testNFTInstance.balanceOf(marketplaceInstance.address);
        expect(true).to.equal(marketplaceBalance.eq(web3.utils.toBN(1)));

        await marketplaceInstance.delistNft(testNFTInstance.address, web3.utils.toBN(1));
        marketplaceBalance = await testNFTInstance.balanceOf(marketplaceInstance.address);
        expect(true).to.equal(marketplaceBalance.eq(web3.utils.toBN(0)));

        const deployerNFTBalance = await testNFTInstance.balanceOf(deployer);
        expect(true).to.equal(deployerNFTBalance.eq(web3.utils.toBN(1)));

        const confirmOwnership = await testNFTInstance.ownerOf(web3.utils.toBN(1));
        expect(confirmOwnership).to.equal(deployer);
    });

    it("account1 should make a bid", async() => {
        const marketplaceInstance = await Marketplace.deployed();
        const testNFTInstance = await TestNFT.deployed();
    });
});
