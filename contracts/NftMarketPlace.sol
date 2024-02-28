// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error NftMarketPlace__NotOwner();
error NftMarketPlace__InsufficientAmount();
error NftMarketPlace__InsufficientPriceSet();
error NftMarketPlace__NowOwner();
error NftMarketPlace__InsufficientAmountSent();
error NftMarketPlace__NotForSale();
error NftMarketPlace__ExchangeFailed();
error NftMarketPlace__OwnerCantBuy();

contract NftMarketPlace is ERC721URIStorage {
    // EVENTS
    event MarketItemCreated(
        uint256 tokenId,
        address indexed creator,
        address indexed approvedOwner,
        uint256 indexed price,
        bool sold
    );

    // VARIABLES
    address private immutable i_owner;
    uint256 private currentTokenId;
    uint256 private s_soldNfts;
    uint256 private listingPrice;
    mapping(uint256 => MarketItem) tokenIdToMarketItem;

    // MODIFIER
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NftMarketPlace__NotOwner();
        }
        _;
    }

    // STRUCT
    struct MarketItem {
        uint256 tokenId; // id of the token
        address seller; // seller of the token (initially the minter)
        address owner; // current owner initially 0 then setApproval to us then create exchange after exchange set to 0 again
        uint256 price; // price to be sold at in WEI
        bool sold; // sold or not
    }

    // CONSTRUCTOR
    constructor() ERC721("VR Art Tokens", "ENMA") {
        i_owner = msg.sender;
        currentTokenId = 1;
        s_soldNfts = 0;
        listingPrice = 0.02 ether;
    }

    // MAIN FUNCTIONS

    // CREATE NFT AND LIST INTO MARKETPLACE
    function createNft(
        uint256 price,
        string memory tokenUri
    ) external payable returns (uint256) {
        if (msg.value < listingPrice) {
            revert NftMarketPlace__InsufficientAmount();
        }
        if (price <= 0) {
            revert NftMarketPlace__InsufficientPriceSet();
        }
        _safeMint(msg.sender, currentTokenId); // create the token
        _setTokenURI(currentTokenId, tokenUri); // ipfs data
        tokenIdToMarketItem[currentTokenId] = MarketItem(
            currentTokenId,
            msg.sender,
            address(0x0),
            price,
            true
        );
        currentTokenId = currentTokenId + 1;
        listItemToMarketPlace(currentTokenId - 1, price, msg.sender);
        return currentTokenId - 1;
    }

    // LIST THE NFT INTO THE MARKETPLACE
    function listItemToMarketPlace(
        uint256 tokenId,
        uint256 price,
        address seller
    ) private {
        if (price <= 0) {
            revert NftMarketPlace__InsufficientPriceSet();
        }
        tokenIdToMarketItem[tokenId] = MarketItem(
            tokenId,
            seller, // THE ONE WHO CALLED MINT FUNCTION OR RELIST FUNCTION
            address(this), // SET TO THE CONTRACT ADDRESS
            price,
            false
        );
        approve(address(this), tokenId); // APPROVED TO BE SOLD
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // RESLIST THE NFT TO SALE THAT YOU BOUGHT AND YOU CAN ALSO USE THIS TO UPDATE THE PRICE OF THE NFT
    function relistNft(
        uint256 tokenId,
        uint256 price
    ) external payable returns (uint256) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NftMarketPlace__NotOwner();
        }
        if (msg.value < listingPrice) {
            revert NftMarketPlace__InsufficientAmount();
        }
        listItemToMarketPlace(tokenId, price, msg.sender);
        s_soldNfts = s_soldNfts - 1;
        return tokenId;
    }

    // SELL THE NFT AND GET MONEY
    function exchangeNft(uint256 tokenId) external payable {
        if (_ownerOf(tokenId) == msg.sender) {
            revert NftMarketPlace__OwnerCantBuy();
        }
        MarketItem memory curItem = tokenIdToMarketItem[tokenId];
        if (curItem.sold == true) {
            revert NftMarketPlace__NotForSale();
        }
        if (msg.value < curItem.price) {
            revert NftMarketPlace__InsufficientAmountSent();
        }
        tokenIdToMarketItem[tokenId].sold = true;
        this.safeTransferFrom(curItem.seller, msg.sender, tokenId);
        s_soldNfts = s_soldNfts + 1;
        address previousOwner = curItem.seller;
        tokenIdToMarketItem[tokenId].seller = msg.sender;
        tokenIdToMarketItem[tokenId].owner = address(0x0);
        (bool callSuccess1, ) = payable(i_owner).call{value: listingPrice}("");
        if (callSuccess1 == false) {
            revert NftMarketPlace__ExchangeFailed();
        }
        (bool callSuccess2, ) = payable(previousOwner).call{value: msg.value}(
            ""
        );
        if (callSuccess2 == false) {
            revert NftMarketPlace__ExchangeFailed();
        }
    }

    // REMOVE NFT FROM BEING LISTED ON MARKETPLACE
    function removeFromListing(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert NftMarketPlace__NotOwner();
        }
        MarketItem memory curItem = tokenIdToMarketItem[tokenId];
        if (curItem.sold == true) {
            revert NftMarketPlace__NotForSale();
        }
        tokenIdToMarketItem[tokenId].sold = true;
        tokenIdToMarketItem[tokenId].owner = address(0x0);
        (bool callSuccess1, ) = payable(i_owner).call{value: listingPrice}("");
        if (callSuccess1 == false) {
            revert NftMarketPlace__ExchangeFailed();
        }
    }

    // RETURNS THE ARRAY OF NFTS KEPT FOR SALE
    function listedItemsForSale() public view returns (MarketItem[] memory) {
        uint256 unsoldItems = currentTokenId - 1 - s_soldNfts;
        MarketItem[] memory tobeReturnedItems = new MarketItem[](unsoldItems);
        uint256 currentIndex = 0;
        for (uint i = 1; i < currentTokenId; i++) {
            if (
                tokenIdToMarketItem[i].sold == false &&
                tokenIdToMarketItem[i].owner == address(this)
            ) {
                // not sold and kept for sale
                tobeReturnedItems[currentIndex] = tokenIdToMarketItem[i];
                currentIndex = currentIndex + 1;
            }
        }
        return tobeReturnedItems;
    }

    // RETURNS THE ARRAY OF NFTS THAT ARE BOUGHT BY ME AND NOT RELISTED BY ME
    function myNftsPurchased() public view returns (MarketItem[] memory) {
        uint256 itemCount = 0;
        for (uint i = 1; i < currentTokenId; i++) {
            if (
                tokenIdToMarketItem[i].sold == true &&
                tokenIdToMarketItem[i].seller == msg.sender
            ) {
                itemCount = itemCount + 1;
            }
        }
        uint256 currentIndex = 0;
        MarketItem[] memory tobeReturnedItems = new MarketItem[](itemCount);
        for (uint i = 1; i < currentTokenId; i++) {
            if (
                tokenIdToMarketItem[i].sold == true &&
                tokenIdToMarketItem[i].seller == msg.sender
            ) {
                tobeReturnedItems[currentIndex] = tokenIdToMarketItem[i];
                currentIndex = currentIndex + 1;
            }
        }
        return tobeReturnedItems;
    }

    // RETURNS THE NFTS THAT ARE KEPT FOR SALE BY SPECIFIC USER
    function myListedNfts() public view returns (MarketItem[] memory) {
        uint256 itemCount = 0;
        for (uint i = 1; i < currentTokenId; i++) {
            if (
                tokenIdToMarketItem[i].sold == false &&
                tokenIdToMarketItem[i].seller == msg.sender
            ) {
                itemCount = itemCount + 1;
            }
        }
        uint256 currentIndex = 0;
        MarketItem[] memory tobeReturnedItems = new MarketItem[](itemCount);
        for (uint i = 1; i < currentTokenId; i++) {
            if (
                tokenIdToMarketItem[i].sold == false &&
                tokenIdToMarketItem[i].seller == msg.sender
            ) {
                tobeReturnedItems[currentIndex] = tokenIdToMarketItem[i];
                currentIndex = currentIndex + 1;
            }
        }
        return tobeReturnedItems;
    }

    // GETTER FOR LISTING PRICE
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // SETTER FOR LISTING PRICE IN WEI
    function setListingPrice(uint256 price) public onlyOwner {
        if (price <= 0) {
            revert NftMarketPlace__InsufficientAmount();
        }
        listingPrice = price;
    }

    // GETTER FOR TOTAL NFTS SOLD BY THE CONTRACT
    function getNumberOfSoldNfts() public view returns (uint256) {
        return s_soldNfts;
    }
}
