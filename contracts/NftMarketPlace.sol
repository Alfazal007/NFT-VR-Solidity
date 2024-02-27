// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NftMarketPlace is ERC721URIStorage {

    // initial storage variables to be initialized in the constructor
    address private immutable i_owner;
    uint256 private currentTokenId;
    uint256 private s_soldNfts;
    constructor() ERC721("VR Art Tokens", "ENMA") {
        i_owner = msg.sender;
        currentTokenId = 0;
        s_soldNfts = 0;
    }



    struct MarketItem {
        uint256 tokenId; // id of the token
        address payable seller; // seller of the token (initially the minter)
        address payable owner; // current owner initially 0 then setApproval to us then create exchange after exchange set to 0 again
        uint256 price; // price to be sold at
        bool sold; // sold or not
    }

    //   Updates the listing price of the contract -> owner (we) can change it (to get benifitted from our marketplace)
    // getListingPrice

    // Mint a token and lists it in the marketplace -- _safeMint setTokenURI 
    // createMarketItem private function to be called from above after creation to be listed and also approval to sell the NFT
    // allows someone to resell a token they have purchased manipulate the number of tokens sold and relist it after changing the ownership getting the price and approval

    // Creates the sale of a marketplace item exchange of money and ownership of the listed NFT

    // Return all unsold market items (to be listed) only if it is listed to be sold
    // Return only items that a user has purchased (my purchase section)
    // Return only items a user has listed (my to be sold section)
}