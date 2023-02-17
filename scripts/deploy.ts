const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [deployer, otherAccount] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  // Please fill out these before running the deploy script
  const TOKENNAME = "";
  const TOKENSYMBOL = "";
  const VERSION = "";

  const SBT = await ethers.getContractFactory("SBT");
  const sbt = await SBT.deploy(TOKENNAME, TOKENSYMBOL, VERSION);

  await sbt.deployed();
  console.log("Contract deployed at:", sbt.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run --network goerli scripts/deploy.ts
// npx hardhat run --network hardhat scripts/deploy.ts
