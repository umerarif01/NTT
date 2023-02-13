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

    event SBTGiven(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        bytes metadata
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) ERC4973(name, symbol, version) {}

    function mint(
        address _to,
        bytes calldata _metadata,
        bytes calldata _signature
    ) public payable returns (uint256) {
        uint256 feeAmount = (msg.value * serviceFee) / 1000;
        uint256 tokenId = give(_to, _metadata, _signature);
        ownerOf[_to] = tokenId;
        tokenData[tokenId] = _metadata;
        serviceFeeCollected += feeAmount;
        emit SBTGiven(msg.sender, _to, tokenId, _metadata);
        return tokenId;
    }

    function mintToMany(
        address[] calldata _recipients,
        bytes calldata _metadata,
        bytes[] calldata _signatures
    ) external virtual {
        require(
            _recipients.length == _signatures.length,
            "giveToMany: recipients and signatures length mismatch"
        );

        for (uint i = 0; i < _recipients.length; i++) {
            uint256 tokenId = give(_recipients[i], _metadata, _signatures[i]);
            emit SBTGiven(msg.sender, _recipients[i], tokenId, _metadata);
        }
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "SBT: token does not exist");
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
