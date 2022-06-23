//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMarketplace.sol";

/**
 * @title Marketplace
 * @notice The smart contract have not been audited. Use at your own risk!
 */
contract Marketplace is IMarketplace, ReentrancyGuard, Ownable {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    bytes4 private _interfaceIdERC721 = 0x80ac58cd;

    /**
     * @dev Reference to ERC1155 standard, and where the interfaceId is coming from
     * https://info.etherscan.com/erc-1155-the-multi-token-standard/
     */
    bytes4 private _interfaceIdERC1155 = 0xd9b67a26;

    mapping(address => List) public listOffers;
    mapping(address => mapping(uint256 => Offer[])) public biddingOffers;
    mapping(address => bool) public whitelistTokens;

    receive() external payable {}
    fallback() external payable {}

    function configTokens(address _tokenAddress, bool _isWhitelist) public onlyOwner {
        whitelistTokens[_tokenAddress] = _isWhitelist;
    }

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
        listOffers[_sender] = List({
            nft: _erc721,
            tokenId: _tokenId,
            amount: 1,
            offerPrice: _offerPrice,
            createdAt: block.timestamp,
            closeOffer: false
        });

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

        listOffers[_sender] = List({
            nft: _erc1155,
            tokenId: _tokenId,
            amount: _amount,
            offerPrice: _offerPrice,
            createdAt: block.timestamp,
            closeOffer: false
        });

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
     * @notice Is not tested if it supports ERC721A
     * @dev Transfers ERC721 or ERC1155 to Marketplace contract
     * @param _nft address of ERC721 or ERC1155
     * @param _tokenId uint tokenId of ERC721 or ERC1155
     * @param _offerPrice price to offer in wei
     * @param _amount amount of tokens for ERC1155
     */
    function listNft(address _nft, uint256 _tokenId, uint256 _offerPrice, uint256 _amount) external nonReentrant {
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
     * @notice Is not tested if it supports ERC721A
     * @dev Transfers ERC721 or ERC1155 back to sender
     * @param _nft address of ERC721 or ERC1155
     * @param _tokenId uint tokenId of ERC721 or ERC1155
     * @param _amount amount of tokens for ERC1155
     */
    function delistNft(address _nft, uint256 _tokenId, uint256 _amount) external nonReentrant {
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
     * @notice Is not tested if it supports ERC721A
     * @dev Bid a price and transfer ETH to an escrow
     * @param _nft address of ERC721 or ERC1155
     * @param _tokenId uint tokenId of ERC721 or ERC1155
     * @param _tokenAddress ERC20 token address
     * @param _offerPrice price to offer 
     */
    function offerBid(address _nft, uint256 _tokenId, address _tokenAddress, uint256 _offerPrice) external payable nonReentrant {
        require(_offerPrice > 0, "Marketplace: Cannot transfer 0 amount");
        require(!listOffers[_tokenAddress].closeOffer, "Marketplace: offer been closed");

        if (_tokenAddress == address(0)) {
            (bool sent,) = payable(address(this)).call{value: _offerPrice}("");
            require(sent, "Marketplace: Failed to send ether");
            biddingOffers[_nft][_tokenId].push(Offer({
                buyer: _msgSender(),
                offerPrice: _offerPrice,
                tokenAddress: address(0)
            }));

            emit BiddingOffer(_nft, _offerPrice, _tokenId, _msgSender());

        } else {
            require(whitelistTokens[_tokenAddress], "Marketplace: token not supported");
            IERC20(_tokenAddress).safeTransferFrom(_msgSender(), address(this), _offerPrice);
            biddingOffers[_nft][_tokenId].push(Offer({
                buyer: _msgSender(),
                offerPrice: _offerPrice,
                tokenAddress: _tokenAddress
            }));

            emit BiddingOffer(_nft, _offerPrice, _tokenId, _msgSender());
        }
    }

    // function cancelBid(address _nft, uint256 _tokenId) external nonReentrant {
    //     Offer[] storage offers = biddingOffers[_nft][_tokenId];
    //     for (uint256 i = 0; i < offers.length; i++) {
    //     }
    // }

    function getBiddingOffers(address _nft, uint256 _tokenId) public view returns(Offer[] memory) {
        return biddingOffers[_nft][_tokenId];
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
