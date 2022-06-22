# HashGlasses 🕶️

Marketplace currently supports ERC721 and ERC1155 by checking the bytes4 of through utility
library provided by OpenZeppelin `ERC165Checker`.

## MVP
The `master` branch contains the stable release

The `mvp` branch contains the following:
* ERC721 support
* ERC20 transfer support
* ETH support

The `dev` branch is the branch that contains unstable release (mainly where I'll be working)

## Unit Tests
* The tests were run on WSL2 (Ubuntu 20.04) at Windows 10 (19044.1706)
* Node 16.15.1 and npm 8.12.1
* Solidity 0.8.7 which is the most stable version for running auditing reports via Slither

## License
Currently the license is under GPL-3.0-or-later
