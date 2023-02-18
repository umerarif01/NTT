const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [deployer, otherAccount] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  // Please fill out these before running the deploy script
  const TOKENNAME = "Decentralized Music Licensing";
  const TOKENSYMBOL = "DML";
  const VERSION = "1.0";

  const DML = await ethers.getContractFactory("DMusicLicensing");
  const dml = await DML.deploy(TOKENNAME, TOKENSYMBOL, VERSION);

  await dml.deployed();
  console.log("Contract deployed at:", dml.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run --network goerli scripts/deploy.ts
// npx hardhat run --network hardhat scripts/deploy.ts
