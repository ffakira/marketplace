//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestNFT1155 is ERC1155 {
    constructor() ERC1155("") {
        _mint(_msgSender(), 1, 1, "");
    }
}
