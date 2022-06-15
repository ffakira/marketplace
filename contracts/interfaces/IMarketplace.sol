//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

interface IMarketplace {
    struct Offer {
        address buyer;
        uint256 offerPrice;
    }

    struct List {
        address nft;
        uint256 tokenId;
        uint256 amount;
        uint256 createdAt;
        bool closeOffer;
    }

    event ListNft(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice
    );

    event DelistNft(
        address indexed owner,
        address indexed nft,
        uint256 indexed tokenId
    );

    event BiddingOffer(
        address indexed nft,
        uint256 indexed offerPrice,
        uint256 indexed tokenId,
        address buyer
    );
}
