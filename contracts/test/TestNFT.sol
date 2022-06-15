//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor() ERC721("NFT", "NFT") {
        _mint(_msgSender(), 1);
    }
}
