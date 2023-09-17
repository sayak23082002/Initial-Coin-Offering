require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API;
const GOERLI_PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.9",
  networks: {
    hardhat: {},
    goerli: {
      url: ALCHEMY_API_KEY,
      accounts: [`0x${GOERLI_PRIVATE_KEY}`]
    }
  }
};