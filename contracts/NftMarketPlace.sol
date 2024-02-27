// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error NftMarketPlace__NotOwner();
error NftMarketPlace__InsufficientAmount();
error NftMarketPlace__InsufficientPriceSet();

contract NftMarketPlace is ERC721URIStorage {

    event MarketItemCreated(uint256 tokenId,
        address indexed creator,
        address indexed approvedOwner,
        uint256 indexed price,
        bool sold
        );

    // initial storage variables to be initialized in the constructor
    address private immutable i_owner;
    uint256 private currentTokenId;
    uint256 private s_soldNfts;
    uint256 private listingPrice;
    
    // constructor to initialize local variables and NFT collections
    constructor() ERC721("VR Art Tokens", "ENMA") {
        i_owner = msg.sender;
        currentTokenId = 0;
        s_soldNfts = 0;
        listingPrice = 0.02 ether;
    }


    modifier onlyOwner {
        if(msg.sender != i_owner) {
            revert NftMarketPlace__NotOwner();
        }
        _;
    }



    // the structure array to be maintained
    struct MarketItem {
        uint256 tokenId; // id of the token
        address seller; // seller of the token (initially the minter)
        address owner; // current owner initially 0 then setApproval to us then create exchange after exchange set to 0 again
        uint256 price; // price to be sold at
        bool sold; // sold or not
    }

    mapping (uint256 => MarketItem) tokenIdToMarketItem; // only the listed items present here


    // Mint a token and lists it in the marketplace -- _safeMint setTokenURI 
    function createNft(uint256 price, string memory tokenUri) public payable returns(uint256) {
        if(msg.value < listingPrice) {
            revert NftMarketPlace__InsufficientAmount();
        }
        if(price <= 0) {
            revert NftMarketPlace__InsufficientPriceSet();
        }
        _safeMint(msg.sender, currentTokenId); // create the token
        _setTokenURI(currentTokenId, tokenUri); // ipfs data
        currentTokenId = currentTokenId + 1;
        listItemToMarketPlace(currentTokenId, price, msg.sender);
        return currentTokenId - 1;
    }

    // createMarketItem private function to be called from above after creation to be listed and also approval to sell the NFT
    function listItemToMarketPlace(uint256 tokenId, uint256 price, address seller) private {
        if(msg.value < listingPrice) {
            revert NftMarketPlace__InsufficientAmount();
        }
        if(price <= 0) {
            revert NftMarketPlace__InsufficientPriceSet();
        }
        tokenIdToMarketItem[tokenId] = MarketItem(
            tokenId,
            seller, // creator
            address(this), // the contract to transfer the ownership
            price,
            false
        );
        approve(address(this), tokenId);
        emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        false
        );
    }
    // allows someone to resell a token they have purchased manipulate the number of tokens sold and relist it after changing the ownership getting the price and approval


    // Creates the sale of a marketplace item exchange of money and ownership of the listed NFT

    // Return all unsold market items (to be listed) only if it is listed to be sold
    // Return only items that a user has purchased (my purchase section)
    // Return only items a user has listed (my to be sold section)
    
    
    
    
    
    
    
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 price) public onlyOwner {
        if(price <= 0) {
            revert NftMarketPlace__InsufficientAmount();
        }
        listingPrice = price;
    }
}