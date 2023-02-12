const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [deployer, otherAccount] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  const SBT = await ethers.getContractFactory("SBT");
  const sbt = await SBT.deploy("MyToken", "MTK", "1.0");

  await sbt.deployed();
  console.log("Contract deployed at:", sbt.address);

  // const metadata = "0x1234";
  // const signer = ethers.utils.keccak256(
  //   ethers.utils.toUtf8Bytes("I agree to the terms and conditions")
  // );
  // const signature = await deployer.signMessage(ethers.utils.arrayify(signer));

  // const tokenId = await sbt
  //   .connect(otherAccount)
  //   .mint(deployer.address, metadata, signature);
  // console.log("Token minted with ID:", tokenId.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run --network goerli scripts/deploy.ts
// npx hardhat run --network hardhat scripts/deploy.ts
