// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract NFTMarketplace is Ownable {

    uint256 public numListings = 1;
    uint256 public tax = 2;
    uint256 public taxAmount;

    mapping(uint256 => Listing) public listings;

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address nftOwner;
        address contract_;
        uint256 price;
        // bool active;
    }

    event ListingCreated(uint256 indexed tokenId, address indexed owner, uint256 price);
    event ListingRemoved(uint256 indexed tokenId, address indexed owner);
    event ListingSold(uint256 indexed tokenId, address indexed owner, address indexed buyer, uint256 price);

    constructor() {}

    /**
     * @notice lists the nft of the seller for sale
     * @param _tokenId the id for the token you want to list
     * @param _price the price for the token
     * @param contractAdress the address of the contract which contains the nft
     */
    function sell(uint256 _tokenId, uint256 _price, address contractAdress) public {
        IERC721 nft = IERC721(contractAdress);
        require(nft.ownerOf(_tokenId) == msg.sender, "NFTMarketplace: sender does not own token");
        require(_price > 0, "NFTMarketplace: price must be greater than 0");

        Listing storage listing = listings[numListings];
        listing.listingId = numListings;
        listing.tokenId = _tokenId;
        listing.nftOwner = msg.sender;
        listing.contract_ = contractAdress;
        listing.price = _price;
        // listing.active = true;

        numListings++;

        emit ListingCreated(_tokenId, msg.sender, _price);
    }

    /**
     * @notice removes the listing
     * @param _listingId listing id of the nft
     */
    function removeListing(uint256 _listingId) public {
        Listing storage listing = listings[_listingId];

        IERC721 nft = IERC721(listing.contract_);
        require(nft.ownerOf(listing.tokenId) == msg.sender, "NFTMarketplace: sender is not owner of listing");

        delete(listings[_listingId]);
        // listing.active = false;

        emit ListingRemoved(listing.tokenId, listing.nftOwner);
    }

    /**
     * @notice allows buyer to buy nft, deducts 2% tax from seller and buyer
     * @param _listingId listing id of the nft buyer wants to buy
     */
    function buyListing(uint256 _listingId) public payable {
        Listing storage listing = listings[_listingId];
        
        (uint256 price, uint256 _tax, uint256 adjustedPrice) = getPriceForListing(listing.price);
        
        // get price + 2% tax from buyer
        // require(listing.active == true, "NFTMarketplace: listing is not active");
        
        require(msg.value == adjustedPrice, "NFTMarketplace: incorrect value sent");

        IERC721 nft = IERC721(listing.contract_);
        // console.log(nft.ownerOf(listing.tokenId), listing.nftOwner);
        require(nft.ownerOf(listing.tokenId) == listing.nftOwner, "NFTMarketplace: token no longer owned by listing owner");

        // listing.active = false;
        taxAmount += (_tax * 2); 

        address oldOwner = listing.nftOwner;

        nft.safeTransferFrom(listing.nftOwner, msg.sender, listing.tokenId);

        listing.nftOwner =  msg.sender;
        
        // deduct 2% tax from seller and send value to seller
        (bool sent,) = payable(oldOwner).call{value: price - _tax}("");
        require(sent, "Failed to send Ether");

        emit ListingSold(listing.tokenId, listing.nftOwner, msg.sender, listing.price);
    }

    /**
     * @notice allows owner to withdraw tax
     */
    function withdraw() public onlyOwner {
        uint taxValue = taxAmount;
        taxAmount = 0;
        (bool sent,) = payable(owner()).call{value: taxValue}("");
        require(sent, "Failed to send Ether");
    }

    // function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }

    /**
     * @notice calculates tax on the given price and returns the adjusted price
     * @param price the price of the nft
     * @return price_ the price of the nft
     * @return _tax the tax on the price of the nft
     * @return adjustedPrice tax + price
     */
    function getPriceForListing(uint256 price) public view returns (uint256 price_, uint256 _tax, uint256 adjustedPrice) {
        uint256 __tax = (price * tax) / 100;
        uint256 _adjustedPrice = price + __tax;
        return (price, __tax, _adjustedPrice);
    }

    function getListingTokenId(uint256 _listingId) public view returns (uint256) {
        return listings[_listingId].tokenId;
    }

    function getListingNftOwner(uint256 _listingId) public view returns (address) {
        return listings[_listingId].nftOwner;
    }

    function getListingContract(uint256 _listingId) public view returns (address) {
        return listings[_listingId].contract_;
    }

    function getListingPrice(uint256 _listingId) public view returns (uint256) {
        return listings[_listingId].price;
    }
}