require("dotenv").config();
async function main() {
  const ICO = await ethers.getContractFactory("ICO");

  // Start deployment, returning a promise that resolves to a contract object
  const ico = await ICO.deploy(process.env.DEPOSIT_ADDRESS);
  console.log("Contract deployed to address:", ico);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });