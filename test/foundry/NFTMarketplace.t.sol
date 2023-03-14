// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/NFTMarketplace.sol";
import "../../contracts/NFT.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace public mp_contract;
    Nft public nft_contract;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        vm.deal(user1, 20 ether);
        vm.deal(user2, 20 ether);
        vm.prank(owner);
        mp_contract = new NFTMarketplace();
        nft_contract = new Nft(address(mp_contract));
    }

    function testSell() public {
        vm.startPrank(user1);
        //create nft
        nft_contract.createToken("some uri");
        
        //give approval to market place contract
        nft_contract.giveApprovalForToken(1);

        //put up for sale in market place contract
        mp_contract.sell(1, 0.1 ether, address(nft_contract));
        vm.stopPrank();

        assertEq (nft_contract.ownerOf(1), user1);
        assertEq (mp_contract.getListingNftOwner(1), user1);
    }

    function testCannotBuy() public {
        vm.startPrank(user1);
        //create nft
        nft_contract.createToken("some uri");
        
        //give approval to market place contract
        // nft_contract.giveApprovalForToken(1);

        //put up for sale in market place contract
        mp_contract.sell(1, 0.1 ether, address(nft_contract));
        
        vm.stopPrank();

        ( , , uint256 adjustedPrice) = mp_contract.getPriceForListing(0.1 ether);
        
        vm.startPrank(user2);
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        mp_contract.buyListing{value: adjustedPrice}(1);
        vm.stopPrank();

        // assertEq (nft_contract.ownerOf(1), user1);
        // assertEq (mp_contract.getListingNftOwner(1), user1);
    }

    function testBuy() public {

        vm.startPrank(user1);
        //create nft
        nft_contract.createToken("some uri");
        
        //give approval to market place contract
        nft_contract.giveApprovalForToken(1);

        //put up for sale in market place contract
        mp_contract.sell(1, 0.1 ether, address(nft_contract));
        
        vm.stopPrank();

        address seller = mp_contract.getListingNftOwner(1);
        uint sellerBalance = seller.balance;

        (uint256 price, uint256 _tax, uint256 adjustedPrice) = mp_contract.getPriceForListing(0.1 ether);
        
        vm.prank(user2);
        
        mp_contract.buyListing{value: adjustedPrice}(1);

        assertEq (nft_contract.ownerOf(1), user2);
        assertEq (mp_contract.getListingNftOwner(1), user2);
        assertEq (seller, user1);
        // assertEq (actual, expected);
        assertEq (sellerBalance + price - _tax, seller.balance);
        assertEq (mp_contract.taxAmount(),  _tax + _tax);
    }

    function testWithdraw() public {
        testBuy();

        uint taxAmount = mp_contract.taxAmount();

        vm.prank(owner);
        mp_contract.withdraw();

        assertEq(taxAmount, owner.balance);
    }
}
