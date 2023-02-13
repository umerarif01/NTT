// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {ERC4973} from "./ERC4973.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SBT is ERC4973, Ownable, ReentrancyGuard {
    uint256 private serviceFee = 25; // 2.5 service fee of the platform
    uint256 private serviceFeeCollected; // total service fee collected by issuing tokens

    // This mapping maps the current owner to its SBT token ID.
    mapping(address => uint256) public ownerOf;
    // This mapping maps the SBT token ID to its metadata
    mapping(uint256 => bytes) public tokenData;
    // This mapping maps the owner's address to an array of all the SBT token IDs they currently own.
    mapping(address => uint256[]) public ownedTokens;

    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) ERC4973(name, symbol, version) {}

    function mint(
        address to,
        bytes calldata metadata,
        bytes calldata signature
    ) public payable returns (uint256) {
        uint256 feeAmount = (msg.value * serviceFee) / 1000;
        uint256 tokenId = give(to, metadata, signature);
        ownerOf[to] = tokenId;
        tokenData[tokenId] = metadata;
        serviceFeeCollected += feeAmount;
        return tokenId;
    }

    function mintToMany(
        address[] calldata _recipients,
        bytes calldata metadata,
        bytes[] calldata _signatures
    ) external virtual {
        require(
            _recipients.length == _signatures.length,
            "giveToMany: recipients and signatures length mismatch"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {}
    }

    function revoke(uint256 tokenId) public {
        unequip(tokenId);
    }

    function withdraw() public onlyOwner nonReentrant {
        require(serviceFeeCollected > 0, "No service fee to withdraw");
        uint256 amount = serviceFeeCollected;
        serviceFeeCollected = 0;
        payable(owner()).transfer(amount);
    }

    function getServiceFee() public view returns (uint256) {
        return serviceFee;
    }

    function setServiceFee(uint256 _serviceFee) public {
        serviceFee = _serviceFee;
    }
}
