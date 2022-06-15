//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
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
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol
     *
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol
     */
     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
     }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     * 
     * Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol
     */
     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
