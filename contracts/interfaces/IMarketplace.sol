//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

/**
 * @title IMarketplace
 * @notice The smart contract have not been audited. Use at your own risk!
 */
interface IMarketplace {
    struct Offer {
        address buyer;
        address tokenAddress;
        uint256 offerPrice;
    }

    struct List {
        address nft;
        uint256 tokenId;
        uint256 offerPrice;
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

    event CancelOffer(
        address indexed nft,
        address indexed buyer,
        uint256 indexed offerPrice,
        address tokenAddress
    );

    function listNft(address _nft, uint256 _tokenId, uint256 _offerPrice, uint256 _amount) external;
    function delistNft(address _nft, uint256 _tokenId, uint256 _amount) external;
    function offerBid(address _nft, uint256 _tokenId, address _tokenAddress, uint256 _offerPrice) external payable;
    // function cancelBid(address _nft, uint256 _tokenId) external;
}
