require('dotenv').config()

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require('hardhat-contract-sizer');
require("hardhat-gas-reporter");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  mocha: {
    timeout: 100000000
  },
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000000,
      },
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/" + process.env.ALCHEMY_KEY,
        blockNumber: 15366446   // 2022-04-27
      }
    },
    polygon: {
      url: "https://rpc.ankr.com/polygon",
      chainId: 137
    },
    mainnet: {
      url: "https://rpc.ankr.com/eth",
      chainId: 1
    },
    optimism: {
      url: "https://rpc.ankr.com/optimism",
      chainId: 10
    },
    arbitrum: {
      url: "https://rpc.ankr.com/arbitrum",
      chainId: 42161
    },
    goerli: {
      url: process.env.GOERLI_ALCHEMY_KEY,
      chainId: 5,
      accounts: [process.env.DEPLOYMENT_PRIVATE_KEY]
      
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY_MAINNET
    }
  },
  gasReporter: {
    enabled: true
  }
};
