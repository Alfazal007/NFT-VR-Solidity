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
        uint256 price; // price to be sold at
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
        currentTokenId = currentTokenId + 1;
        listItemToMarketPlace(currentTokenId, price, msg.sender);
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

    function relistNft(uint256 tokenId, uint256 price) external payable {}

    // Creates the sale of a marketplace item exchange of money and ownership of the listed NFT
    function exchangeNft(uint256 tokenId) external payable {
        MarketItem memory curItem = tokenIdToMarketItem[tokenId];
        if (curItem.sold == true) {
            revert NftMarketPlace__NotForSale();
        }
        if (msg.value < curItem.price) {
            revert NftMarketPlace__InsufficientAmountSent();
        }
        tokenIdToMarketItem[tokenId].sold = true;
        safeTransferFrom(curItem.seller, msg.sender, tokenId);
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

    // Return all unsold market items (to be listed) only if it is listed to be sold
    // Return only items that a user has purchased (my purchase section)
    // Return only items a user has listed (my to be sold section)

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 price) public onlyOwner {
        if (price <= 0) {
            revert NftMarketPlace__InsufficientAmount();
        }
        listingPrice = price;
    }
}
