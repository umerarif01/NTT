// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {ERC4973} from "./ERC4973.sol";

contract SBT is ERC4973 {
    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) ERC4973(name, symbol, version) {}

    function mint(
        address to,
        bytes calldata metadata,
        bytes calldata signature
    ) public returns (uint256) {
        uint256 tokenId = give(to, metadata, signature);
        return tokenId;
    }

    function revoke(uint256 tokenId) public {
        unequip(tokenId);
    }
}
