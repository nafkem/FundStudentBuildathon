// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract NFT is ERC721URIStorage {

    uint256 private _tokenIds;
    address private _baseTokenURI;

    struct Donation {
        address donor;
        string ipfsHash;
    }

    Donation[] public donations;

    constructor(string memory name,string memory symbol,string memory baseURI) ERC721(name, symbol) {}

    function mintNFT(address _recipient, string memory _ipfsHash) external {
        uint256 tokenId = donations.length; // Use donation count as token ID (simplified)
        donations.push(Donation(_recipient, _ipfsHash));
        _mint(_recipient, tokenId);
        _setTokenURI(tokenId, _ipfsHash);
    }

    
     function _baseURI() internal pure override returns (string memory) {
        return
            "https://ipfs.filebase.io/ipfs/QmPTEaHudXURDcCxieZmujGbDRHFqYmMJzUUr9shmLtwns/";
    }

    function getDonationCount() external view returns (uint256) {
        return donations.length;
    }
}


