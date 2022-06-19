//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    function removeFunds(IERC20 _tokenAddress, uint256 _amount) public onlyOwner {
        if (address(_tokenAddress) != address(0)) {
            IERC20(_tokenAddress).transfer(_msgSender(), _amount);
        }
    }
}
