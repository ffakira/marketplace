# HashGlasses 🕶️
Marketplace currently supports ERC721 and ERC1155 by checking the bytes4 of through utility
library provided by OpenZeppelin `ERC165Checker`.

## Getting started
Install npm modules

```sh
$ npm i
```

## Unit Tests
* The tests were run on WSL2 (Ubuntu 20.04) at Windows 10 (19044.1706)
* Node 16.15.1 and npm 8.12.1

Open terminal 1: start running local ganache at `port 8545`

```sh
$ npm run ganache
```

Open terminal 2: run unit tests
```sh
$ npm test
```

## Features
The `master` branch contains the following:
* ERC721 and ERC1155 support
* ERC20 transfer support
* ETH support

## License
Currently the license is under GPL-3.0-or-later
