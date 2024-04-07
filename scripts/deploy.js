// const hre = require("hardhat");
const { verify } = require("./verify.js");
const { ethers, network } = require("hardhat");

async function main() {
  const name = "WeaveNFTHUB"; // Name of the NFT contract
  const symbol = "NFT"; // Symbol of the NFT contract
  const baseURI = "mPTEaHudXURDcCxieZmujGbDRHFqYmMJzUUr9shmLtwns";
  //const uSDT = "0xbFe441DE1f299AEaE42569A2ce66954D30AbF75A";
  

  // console.log("Deploying NFT contract with the name ", name, " symbol ", symbol, "baseURI", baseURI);
  // let nftArgs = [name, symbol, baseURI];
  // const NFT = await ethers.deployContract("NFT", nftArgs, {
  // });

  // if (network.config.chainId === 11155420 && process.env.ETHERSCAN_API_KEY) {
  //   await NFT.waitForDeployment(6);
  //   await verify(NFT.target, nftArgs);
  // } else {
  //   console.log("Contract cannot be verified on Hardhat Network");
  // }

  // console.log(`NFT contract deployed to ${NFT.target}`);

  // Deploy the FundStudent contract
  console.log("Deploying FundStudent contract");
  let FundStudentArgs = [];
  const FundStudent = await ethers.deployContract("FundStudent", FundStudentArgs, {
    //libraries: { SignUtils: SignUtils.target },
  });

  if (network.config.chainId === 11155420  && process.env.ETHERSCAN_API_KEY) {
    await FundStudent.waitForDeployment(6);
    await verify(FundStudent.target, []);
  } else {
    console.log("Contract cannot be verified on Hardhat Network");
  }

  console.log(`FundStudent contract deployed to ${FundStudent.target}`);

}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
