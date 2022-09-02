

import { HardhatUserConfig } from "hardhat/config";
import "dotenv/config";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more


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
        blockNumber: 
        15459540    // 2022-04-27
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
