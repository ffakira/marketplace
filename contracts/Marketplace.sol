//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Marketplace is Context, IERC721Receiver {
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

    mapping(address => List) public listOffers;
    mapping(address => mapping(uint256 => Offer)) public biddingOffers;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function listNft(address _nft, uint256 _tokenId, uint256 _offerPrice) public {
        listOffers[_msgSender()].nft = _nft;
        listOffers[_msgSender()].tokenId = _tokenId;
        listOffers[_msgSender()].amount = _offerPrice;
        listOffers[_msgSender()].createdAt = block.timestamp;
        listOffers[_msgSender()].closeOffer = false;

        IERC721(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId);
        emit ListNft(_msgSender(), _nft, _tokenId, _offerPrice);
    }

    function delistNft(address _nft, uint256 _tokenId) public {
        IERC721(_nft).approve(_msgSender(), _tokenId);
        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);
        emit DelistNft(_msgSender(), _nft, _tokenId);
    }

    function offerBidPrice(address _nft, uint256 _tokenId, uint256 _offerPrice) public {

    }
}
