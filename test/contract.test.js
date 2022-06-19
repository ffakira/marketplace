/**
 * @author HashGlasses Team
 */
const { BigNumber } = require("@ethersproject/bignumber");
const { ethers } = require("hardhat");
const { expect } = require("chai");
const truffleAssert = require("truffle-assertions");

describe("Treasury and TestToken", function() {
    beforeEach(async function() {
        [this.deployer, ...this.accounts] = await ethers.getSigners();

        const TestToken = await ethers.getContractFactory("TestToken");
        const Treasury = await ethers.getContractFactory("Treasury");

        this.testToken = await TestToken.deploy();
        this.treasury = await Treasury.deploy();
    });

    it("should return 1_000_000 ether minted back to deployer.", async function() {
        const balanceOf = await this.testToken.balanceOf(this.deployer.address);
        expect(balanceOf).to.deep.equal(BigNumber.from(ethers.utils.parseEther("1000000")));
    });

    it("should transfer 100 wei to treasury contract", async function() {
        // @dev treasury balance of TToken = 0 wei
        let treasuryBalance = await this.testToken.balanceOf(this.treasury.address);
        expect(treasuryBalance).to.deep.equal(BigNumber.from("0"));

        // @dev approve TToken and transfer to Treasury contract
        await this.testToken.approve(this.deployer.address, BigNumber.from("100"));
        await this.testToken.transferFrom(this.deployer.address, this.treasury.address, BigNumber.from("100"));

        // @dev treasury balance of TToken = 100 wei
        treasuryBalance = await this.testToken.balanceOf(this.treasury.address);
        expect(treasuryBalance).to.deep.equal(BigNumber.from("100"));
    });

    it("should remove 25 wei from removeFunds", async function() {
        // @dev treasury balance of TToken = 100 wei
        await this.testToken.approve(this.deployer.address, BigNumber.from("100"));
        await this.testToken.transferFrom(this.deployer.address, this.treasury.address, BigNumber.from("100"));

        // @dev treasury balance of TToken = 75 wei
        await this.treasury.removeFunds(this.testToken.address, BigNumber.from("25"));
        const treasuryBalance = await this.testToken.balanceOf(this.treasury.address);
        expect(treasuryBalance).to.deep.equal(BigNumber.from("75"));
    });
    
    it("should fail if you try to remove funds from non-deployer address", async function() {
        await truffleAssert.fails(
            this.treasury.connect(this.accounts[1]).removeFunds(
                this.testToken.address,
                BigNumber.from("1")
            )
        );
    });
});

describe("Marketplace", function() {
    beforeEach(async function() {
        [this.deployer, ...this.accounts] = await ethers.getSigners();

        const Marketplace = await ethers.getContractFactory("Marketplace");
        const TestNFT = await ethers.getContractFactory("TestNFT");

        this.testNft = await TestNFT.deploy();
        this.marketplace = await Marketplace.deploy();
    });

    it("should list the ERC721 NFT on the marketplace", async function() {
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        const deployerNftBalance = await this.testNft.balanceOf(this.deployer.address);
        expect(deployerNftBalance).to.deep.equal(BigNumber.from("1"));

        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice);

        const offer = await this.marketplace.listOffers(this.deployer.address);
        expect(offer["nft"]).to.equal(this.testNft.address);
        expect(offer["tokenId"]).to.deep.equal(BigNumber.from("1"));
        expect(offer["amount"]).to.deep.equal(nftPrice);
        expect(offer["closeOffer"]).to.equal(false);

        const confirmOwnership = await this.testNft.ownerOf(BigNumber.from("1"));
        expect(confirmOwnership).to.equal(this.marketplace.address);
    });

    it("should delist the NFT from the marketplace", async function() {
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), BigNumber.from(ethers.utils.parseEther("10")));

        // @dev Marketplace contains the user's NFT
        let marketplaceNftBalance = await this.testNft.balanceOf(this.marketplace.address);
        expect(marketplaceNftBalance).to.deep.equal(BigNumber.from("1"));

        await this.marketplace.delistNft(this.testNft.address, BigNumber.from("1"));
        marketplaceNftBalance = await this.testNft.balanceOf(this.marketplace.address);
        expect(marketplaceNftBalance).to.deep.equal(BigNumber.from("0"));

        const deployerNFtBalance = await this.testNft.balanceOf(this.deployer.address);
        expect(deployerNFtBalance).to.deep.equal(BigNumber.from("1"));

        const confirmOwnership = await this.testNft.ownerOf(BigNumber.from("1"));
        expect(confirmOwnership).to.deep.equal(this.deployer.address);
    });
});
