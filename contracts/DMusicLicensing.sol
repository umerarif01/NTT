// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {ERC4973} from "./ERC4973.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
@title DMusicLicensing Contract
@dev Smart contract for creating and managing SBT tokens.
*/
contract DMusicLicensing is ERC4973, Ownable, ReentrancyGuard {
    uint256 private serviceFee = 25; // 2.5 service fee of the platform
    uint256 private serviceFeeCollected; // Total service fee collected by issuing tokens

    mapping(address => uint256) public ownerOf; //  Maps the owner to its SBT token ID
    mapping(uint256 => bytes) public tokenData; //  Maps the SBT token ID to its metadata
    mapping(uint256 => uint256) public tokenExpiration; //  Maps a token ID to its expiration date
    mapping(uint256 => address[]) private recipients; // Maps token IDs to an array of recipients
    mapping(uint256 => uint256[]) private recipientShares; // Maps token IDs to an array of recipient percentage shares

    event SBTGiven(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        bytes metadata
    );

    event SBTBurned(uint256 tokenId);

    /**
    @dev Constructor for SBT contract
    @param name The name of the token
    @param symbol The symbol of the token
    @param version The version of the token
*/
    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) ERC4973(name, symbol, version) {}

    /**

    @dev Mint SBT token to a single recipient
    @param _to The recipient's address
    @param _metadata The metadata associated with the token
    @param _signature The signature of the token required to validate minting operation
    @param _newRecipients The array of recipient addresses for splitting peyment 
    @param _recipientPercentages The array of recipient percentage shares
    @param _expirationDate The expiration date of the token
    @param _cost The cost of the token
    @return The ID of the newly minted token
    Emits SBTGiven event for the recipient that received the token
*/
    function mint(
        address _to,
        bytes calldata _metadata,
        bytes calldata _signature,
        address[] memory _newRecipients,
        uint256[] memory _recipientPercentages,
        uint256 _expirationDate,
        uint256 _cost
    ) public payable returns (uint256) {
        require(msg.value == _cost, "SBT: amount sent does not match cost");
        uint256 feeAmount = (msg.value * serviceFee) / 1000;
        uint256 payment = msg.value - feeAmount;
        serviceFeeCollected += feeAmount;

        // Distribute payment among recipients
        for (uint i = 0; i < _newRecipients.length; i++) {
            require(
                _recipientPercentages[i] > 0,
                "Invalid recipient percentage"
            );
            uint256 amount = (payment * _recipientPercentages[i]) / 100;
            require(amount > 0, "Amount to be distributed is too small");
            payable(_newRecipients[i]).transfer(amount);
        }

        // Mint the SBT
        uint256 tokenId = give(_to, _metadata, _signature);
        ownerOf[_to] = tokenId;
        tokenData[tokenId] = _metadata;
        tokenExpiration[tokenId] = _expirationDate;

        // Store the recipients and their percentage shares for this token ID
        recipients[tokenId] = _newRecipients;
        recipientShares[tokenId] = _recipientPercentages;

        emit SBTGiven(msg.sender, _to, tokenId, _metadata);
        return tokenId;
    }

    /**
     * @dev Mint SBT tokens to multiple  _to, and distribute the payment among the recipients.
     * @param _to An array of _to addresses to whom the SBT tokens will be minted.
     * @param _metadata The metadata associated with the tokens.
     * @param _signatures An array of signatures required to validate the minting operation.
     * @param _newRecipients An array of recipient addresses who will receive a share of the payment.
     * @param _recipientPercentages An array of percentage shares for each recipient.
     * @param _expirationDate The expiration date of the tokens.
     * @param _cost The cost of each token.
     * Emits SBTGiven event for each recipient that received a token.
     */
    function mintToMany(
        address[] memory _to,
        bytes calldata _metadata,
        bytes[] calldata _signatures,
        address[] memory _newRecipients,
        uint256[] memory _recipientPercentages,
        uint256 _expirationDate,
        uint256 _cost
    ) public payable {
        require(
            _to.length == _signatures.length,
            "SBT: _to and _signature arrays must have the same length"
        );

        require(
            msg.value == _cost * _to.length,
            "SBT: amount sent does not match cost"
        );

        uint256 feeAmount = (msg.value * serviceFee) / 1000;
        uint256 payment = msg.value - feeAmount;
        serviceFeeCollected += feeAmount;

        // Distribute payment among recipients
        for (uint i = 0; i < _newRecipients.length; i++) {
            require(
                _recipientPercentages[i] > 0,
                "Invalid recipient percentage"
            );
            uint256 amount = (payment * _recipientPercentages[i]) / 100;
            require(amount > 0, "Amount to be distributed is too small");
            payable(_newRecipients[i]).transfer(amount);
        }
        // Mint the SBT to all _to
        for (uint i = 0; i < _to.length; i++) {
            uint256 tokenId = give(_to[i], _metadata, _signatures[i]);
            address owner = _to[i];
            ownerOf[owner] = tokenId;
            tokenData[tokenId] = _metadata;
            tokenExpiration[tokenId] = _expirationDate;
            // Store the recipients and their percentage shares for this token ID
            recipients[tokenId] = _newRecipients;
            recipientShares[tokenId] = _recipientPercentages;
            bytes calldata metadata = _metadata;
            emit SBTGiven(msg.sender, owner, tokenId, metadata);
        }
    }

    /**
     * @notice Revokes the ownership of the specified token and removes its associated metadata.
     * @dev Requires the token to exist and be currently owned. Only the owner of the contract can call this function
     * @param tokenId The ID of the token to revoke.
     * @dev Emits a {TokenRevoked} event.
     */
    function revoke(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "SBT: token does not exist");
        unequip(tokenId);
        emit SBTBurned(tokenId);
    }

    /**
     * @notice Revokes the ownership of the specified token and removes its associated metadata.
     * @dev Burns the token with the given ID if it has already expired. Only the owner of the contract can call this function
     * @param tokenId The ID of the token to revoke.
     * @dev Emits a {TokenRevoked} event.
     */
    function burnIfExpired(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "SBT: token does not exist");
        require(
            block.timestamp >= tokenExpiration[tokenId],
            "SBT: token has not expired yet"
        );
        unequip(tokenId);
        emit SBTBurned(tokenId);
    }

    /**
     * @notice Withdraws the accumulated service fees and sends them to the contract owner.
     * @dev Only the owner of the contract can call this function.
     * @dev The function will throw if there are no service fees to withdraw.
     */

    function withdraw() public onlyOwner nonReentrant {
        require(serviceFeeCollected > 0, "No service fee to withdraw");
        uint256 amount = serviceFeeCollected;
        serviceFeeCollected = 0;
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Returns the array of recipients of a given token ID.
     * @param tokenId uint256 ID of the token to query.
     * @return An array of addresses that are recipients of the token.
     */
    function getRecipients(
        uint256 tokenId
    ) public view returns (address[] memory) {
        return recipients[tokenId];
    }

    /**
     * @dev Returns the array of recipient percentage shares of a given token ID.
     * @param tokenId uint256 ID of the token to query.
     * @return An array of uint256 values that are the percentage shares of each recipient.
     */
    function getRecipientShares(
        uint256 tokenId
    ) public view returns (uint256[] memory) {
        return recipientShares[tokenId];
    }

    /**
     * @dev Returns the current service fee.
     * @return The current service fee as an unsigned integer.
     */
    function getServiceFee() public view returns (uint256) {
        return serviceFee;
    }

    /**
     * @dev Sets the service fee for minting tokens.
     * @param _serviceFee The new service fee to set.
     */
    function setServiceFee(uint256 _serviceFee) public onlyOwner {
        serviceFee = _serviceFee;
    }
}
