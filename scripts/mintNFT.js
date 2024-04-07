require('dotenv').config();


const {Contract,parseEther, Wallet, JsonRpcProvider} = require('ethers');

const API_URL = process.env.API_URL;

const provider = new JsonRpcProvider(API_URL)

const contract = require("../artifacts/contracts/hubtoken.sol/MyNFT.json");

const privateKey = process.env.PRIVATE_KEY
const signer = new Wallet(privateKey, provider)
const tokenId = 1

// Get contract ABI and address
const abi = contract.abi
const contractAddress = '0x8907eaBBa64B8f4729EB82b28ff508CCaC20c924'
// Create a contract instance
const myNftContract = new Contract(contractAddress, abi, signer)

// Get the NFT Metadata IPFS URL
const tokenUri = "https://ipfs.filebase.io/ipfs/QmPTEaHudXURDcCxieZmujGbDRHFqYmMJzUUr9shmLtwns"

// Call mintNFT function
const mint = async () => {
    let nftTxn = await myNftContract.mint(signer.address, tokenId, {value:parseEther("0.0005")})
    await nftTxn.wait()
    console.log(`NFT Minted! Check it out at: https://sepolia.arbiscan.io/tx/${nftTxn.hash}`)
}

mint()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });