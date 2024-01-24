// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    using SafeERC20 for IERC20;

    struct Listing {
        address seller;
        IERC721 nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;

    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed buyer, uint256 price);
    event NFTListingCanceled(uint256 indexed listingId);

    modifier onlyValidListing(uint256 listingId) {
        require(listings[listingId].active, "Listing not active");
        _;
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner of the NFT");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        listings[nextListingId] = Listing({
            seller: msg.sender,
            nftContract: nft,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit NFTListed(nextListingId, msg.sender, nftContract, tokenId, price);

        nextListingId++;
    }

    function buyNFT(uint256 listingId) external payable onlyValidListing(listingId) {
        Listing storage listing = listings[listingId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        listing.nftContract.safeTransferFrom(address(this), msg.sender, listing.tokenId);
        listing.seller.transfer(msg.value);

        emit NFTSold(listingId, msg.sender, msg.value);

        delete listings[listingId];
    }

    function cancelListing(uint256 listingId) external onlyOwner onlyValidListing(listingId) {
        Listing storage listing = listings[listingId];
        listing.nftContract.safeTransferFrom(address(this), listing.seller, listing.tokenId);

        emit NFTListingCanceled(listingId);

        delete listings[listingId];
    }

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }
}
