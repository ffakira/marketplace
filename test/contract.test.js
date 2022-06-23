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
        const TestNFT1155 = await ethers.getContractFactory("TestNFT1155");
        const TestToken = await ethers.getContractFactory("TestToken");

        this.testNft = await TestNFT.deploy();
        this.marketplace = await Marketplace.deploy();
        this.testNft1155 = await TestNFT1155.deploy();
        this.testToken = await TestToken.deploy();
    });

    it("should list the ERC721 NFT on the marketplace", async function() {
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        const deployerNftBalance = await this.testNft.balanceOf(this.deployer.address);
        expect(BigNumber.from("1")).to.deep.equal(deployerNftBalance);

        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        const offer = await this.marketplace.listOffers(this.deployer.address);
        expect(this.testNft.address).to.equal(offer["nft"]);
        expect(BigNumber.from("1")).to.deep.equal(offer["tokenId"]);
        expect(nftPrice).to.deep.equal(offer["offerPrice"]);
        expect(false).to.equal(offer["closeOffer"]);

        const confirmOwnership = await this.testNft.ownerOf(BigNumber.from("1"));
        expect(this.marketplace.address).to.equal(confirmOwnership);
    });

    it("should list the ERC1155 NFT on the marketplace", async function() {
        await this.testNft1155.connect(this.deployer).setApprovalForAll(this.marketplace.address, true);
        const isApproved = await this.testNft1155.isApprovedForAll(this.deployer.address, this.marketplace.address);
        expect(true).to.equal(isApproved);

        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.marketplace.listNft(this.testNft1155.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        const offer = await this.marketplace.listOffers(this.deployer.address);
        expect(this.testNft1155.address).to.equal(offer["nft"]);
        expect(BigNumber.from("1")).to.deep.equal(offer["tokenId"]);
        expect(nftPrice).to.deep.equal(offer["offerPrice"]);
        expect(false).to.equal(offer["closeOffer"]);
    });

    it("should fail listing an ERC20 on the marketplace", async function() {
        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));

        await truffleAssert.fails(
            this.marketplace.listNft(this.testToken.address, BigNumber.from("1"), nftPrice, BigNumber.from("1")),
            "Marketplace: Not compatible token"
        );
    });

    it("should delist ERC721 from the marketplace", async function() {
        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        let balanceOf = await this.testNft.balanceOf(this.deployer.address);
        expect(BigNumber.from("0")).to.deep.equal(balanceOf);

        await this.marketplace.delistNft(this.testNft.address, BigNumber.from("1"), BigNumber.from("0"));
        balanceOf = await this.testNft.balanceOf(this.deployer.address);
        expect(BigNumber.from("1")).to.deep.equal(balanceOf);

        const marketplaceBalance = await this.testNft.balanceOf(this.marketplace.address);
        expect(BigNumber.from("0")).to.deep.equal(marketplaceBalance);
    });

    it("should make an offer to NFT with eth", async function() {
        const nftPrice = BigNumber.from(ethers.utils.parseEther("1"));
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        await this.marketplace.connect(this.accounts[1]).offerBid(
            this.testNft.address, BigNumber.from("1"), `0x${'0'.repeat(40)}`, nftPrice,
            { value: nftPrice }
        );

        const [getBiddingOffer] = await this.marketplace.getBiddingOffers(this.testNft.address, BigNumber.from("1"));
        expect(`0x${'0'.repeat(40)}`).to.equal(getBiddingOffer["tokenAddress"]);
        expect(this.accounts[1].address).to.equal(getBiddingOffer["buyer"]);
        expect(nftPrice).to.deep.equal(getBiddingOffer["offerPrice"]);

        const marketplaceBalance = await this.marketplace.getBalance();
        expect(nftPrice).to.deep.equal(marketplaceBalance);
    });

    it("should make an offer to NFT with ERC20", async function() {
        //@dev transfer 10ETH token to account1
        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.testToken.transfer(this.accounts[1].address, nftPrice);

        let account1 = await this.testToken.balanceOf(this.accounts[1].address);
        expect(nftPrice).to.deep.equal(account1);

        //@dev list nft from account0
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        //@dev make an offer from account1 with ERC20
        await this.marketplace.configTokens(this.testToken.address, true);
        await this.testToken.connect(this.accounts[1]).approve(this.marketplace.address, nftPrice);
        await this.marketplace.connect(this.accounts[1]).offerBid(
            this.testNft.address, BigNumber.from("1"), this.testToken.address, nftPrice
        );

        const marketplaceBalance = await this.testToken.balanceOf(this.marketplace.address);
        expect(nftPrice).to.deep.equal(marketplaceBalance);
    });

    it("shoud fail offering 0 amount", async function() {
        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));
        
        await truffleAssert.fails(
            this.marketplace.connect(this.accounts[1]).offerBid(
                this.testNft.address, BigNumber.from("1"), `0x${'0'.repeat(40)}`, BigNumber.from("0"),
                { value: BigNumber.from("0") }
            ),
            "Marketplace: Cannot transfer 0 amount"
        );
    });

    it("should fail to transfer non-whitelisted address", async function() {
        const nftPrice = BigNumber.from(ethers.utils.parseEther("10"));
        await this.testToken.transfer(this.accounts[1].address, nftPrice);

        await this.testNft.approve(this.marketplace.address, BigNumber.from("1"));
        await this.marketplace.listNft(this.testNft.address, BigNumber.from("1"), nftPrice, BigNumber.from("1"));

        await this.testToken.connect(this.accounts[1]).approve(this.marketplace.address, nftPrice);
        await truffleAssert.fails(
            this.marketplace.connect(this.accounts[1]).offerBid(
                this.testNft.address, BigNumber.from("1"), this.testToken.address, nftPrice
            ),
            "Marketplace: token not supported"
        );
    });
});
