//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMarketplace.sol";

/**
 * @title Marketplace
 * @notice The smart contract have not been audited. Use at your own risk!
 */
contract Marketplace is Context, IMarketplace, ReentrancyGuard {
    using ERC165Checker for address;
    bytes4 private _interfaceIdERC721 = 0x80ac58cd;
    bytes4 private _interfaceIdERC1155 = 0xf23a6e61;
    
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

    function _transferERC721(address _sender, address _erc721, uint256 _tokenId, uint256 _offerPrice) internal {
        require(_erc721 != address(0) || _sender != address(0), "Marketplace: invalid operation for zero address");
        listOffers[_sender].nft = _erc721;
        listOffers[_sender].tokenId = _tokenId;
        listOffers[_sender].amount = 1;
        listOffers[_sender].offerPrice = _offerPrice;
        listOffers[_sender].createdAt = block.timestamp;
        listOffers[_sender].closeOffer = false;

        IERC721(_erc721).safeTransferFrom(_sender, address(this), _tokenId);
        emit ListNft(_sender, _erc721, _tokenId, _offerPrice);
    }

    function _delistERC721(address _sender, address _erc721, uint256 _tokenId) internal {
        IERC721(_erc721).approve(_sender, _tokenId);
        IERC721(_erc721).safeTransferFrom(address(this), _sender, _tokenId);

        delete listOffers[_sender];
        emit DelistNft(_sender, _erc721, _tokenId);
    }

    function _transferERC1155(address _sender, address _erc1155, uint256 _tokenId, uint256 _amount, uint256 _offerPrice) internal {
        require(_amount > 0, "Marketplace: cannot transfer 0 amount of tokens");
        require(_erc1155 != address(0) || _sender != address(0), "Marketplace: invalid operation for zero address");
        listOffers[_sender].nft = _erc1155;
        listOffers[_sender].tokenId = _tokenId;
        listOffers[_sender].amount = _amount;
        listOffers[_sender].offerPrice = _offerPrice;
        listOffers[_sender].createdAt = block.timestamp;
        listOffers[_sender].closeOffer = false;

        IERC1155(_erc1155).safeTransferFrom(_sender, address(this), _tokenId, _amount, "");
        emit ListNft(_sender, _erc1155, _tokenId, _offerPrice);
    }

    function _delistERC1155(address _sender, address _erc1155, uint256 _tokenId, uint256 _amount) internal {
        // @debug: requires additional attention, not tested.
        IERC1155(_erc1155).setApprovalForAll(address(this), true);
        IERC1155(_erc1155).safeTransferFrom(address(this), _sender, _tokenId, _amount, "");

        delete listOffers[_sender];
        emit DelistNft(_sender, _erc1155, _tokenId);
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Transfers ERC721 or ERC1155 to Marketplace contract
     * @param _nft address of ERC721 or ERC1155
     * @param _tokenId uint tokenId of ERC721 or ERC1155
     * @param _offerPrice price to offer in wei
     * @param _amount amount of tokens for ERC1155
     */
    function listNft(address _nft, uint256 _tokenId, uint256 _offerPrice, uint256 _amount) external {
        bool supportERC721 = _nft.supportsInterface(_interfaceIdERC721);
        bool supportERC1155 = _nft.supportsInterface(_interfaceIdERC1155);
        require(supportERC721 || supportERC1155, "Marketplace: Not compatible token");

        if (supportERC721) {
            _transferERC721(_msgSender(), _nft, _tokenId, _offerPrice);
        }

        if (supportERC1155) {
            _transferERC1155(_msgSender(), _nft, _tokenId, _amount, _offerPrice);
        }
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Transfers ERC721 back to sender
     * @param _nft address of ERC721
     * @param _tokenId uint tokenId of ERC721
     * @param _amount amount of tokens for ERC1155
     */
    function delistNft(address _nft, uint256 _tokenId, uint256 _amount) external {
        bool supportERC721 = _nft.supportsInterface(_interfaceIdERC721);
        bool supportERC1155 = _nft.supportsInterface(_interfaceIdERC1155);
        require(supportERC721 || supportERC1155, "Marketplace: Not compatible token");

        if (supportERC721) {
            _delistERC721(_msgSender(), _nft, _tokenId);
        }

        if (supportERC1155) {
            _delistERC1155(_msgSender(), _nft, _tokenId, _amount);
        }
    }

    /**
     * @notice Is not tested if it supports ERC1155
     * @dev Bid a price and transfer ETH to an escrow
     * @param _nft address of ERC721
     * @param _tokenId uint tokenId of ERC721
     * @param _offerPrice price to offer 
     */
    function offerBidPrice(address _nft, uint256 _tokenId, uint256 _offerPrice) external payable nonReentrant {
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
