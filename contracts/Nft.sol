// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Nft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Tracking the no of tokens minted
    // address public contractAddress; // Address to allow NFT to be interacted with

    constructor() ERC721("TEST", "TST") {
        // contractAddress = marketPlaceAddress;
    }

    // This function is called when the token is to be created
    function createToken(string memory _tokenURI) public returns (uint256) {
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current(); // The new token id is the current value of the counter
        _mint(msg.sender, newTokenId); // mint the token to the sender
        _setTokenURI(newTokenId, _tokenURI); // set the tokenURI to the tokenId.
        // setApprovalForAll(contractAddress, true); // set the contract as an approved token
        return newTokenId;
    }

    // function giveApprovalForToken(uint256 tokenId) public {
    //     approve(contractAddress, tokenId); // set the contract as an approved token
    // }
}
