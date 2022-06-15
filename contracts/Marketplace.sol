//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IMarketplace.sol";

/**
 * @title Marketplace
 * @notice The smart contract have not been audited. Use at your own risk!
 */
contract Marketplace is Context, IERC721Receiver, IMarketplace {
    mapping(address => List) public listOffers;
    mapping(address => mapping(uint256 => Offer[])) public biddingOffers;

    /**
     * @dev `onERC221Received` is a required function in order to transfer to Marketplace smart contract
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Transfers ERC721 to Marketplace contract
     * @param _nft address of ERC721
     * @param _tokenId uint tokenId of ERC721
     * @param _offerPrice price to offer in wei
     */
    function listNft(address _nft, uint256 _tokenId, uint256 _offerPrice) public {
        listOffers[_msgSender()].nft = _nft;
        listOffers[_msgSender()].tokenId = _tokenId;
        listOffers[_msgSender()].amount = _offerPrice;
        listOffers[_msgSender()].createdAt = block.timestamp;
        listOffers[_msgSender()].closeOffer = false;

        IERC721(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId);
        emit ListNft(_msgSender(), _nft, _tokenId, _offerPrice);
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Transfers ERC721 back to sender
     * @param _nft address of ERC721
     * @param _tokenId uint tokenId of ERC721
     */
    function delistNft(address _nft, uint256 _tokenId) public {
        IERC721(_nft).approve(_msgSender(), _tokenId);
        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);

        delete listOffers[_msgSender()];
        emit DelistNft(_msgSender(), _nft, _tokenId);
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Bid a price and transfer ETH to an escrow
     * @param _nft address of ERC721
     * @param _tokenId uint tokenId of ERC721
     * @param _offerPrice price to offer 
     */
    function offerBidPrice(address _nft, uint256 _tokenId, uint256 _offerPrice) public payable {
        (bool sent,) = address(this).call{value: _offerPrice}("");
        require(sent, "Marketplace: Failed to send ether");
        require(true, "Marketplace: Bid higher then the floor price");

        biddingOffers[_nft][_tokenId].push(Offer({
            buyer: _msgSender(),
            offerPrice: _offerPrice
        }));
        emit BiddingOffer(_nft, _offerPrice, _tokenId, _msgSender());
    }
}
