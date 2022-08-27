const { BigNumber } = require("@ethersproject/bignumber");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
const uniAddress = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984"
const wbtcAddress = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"

const factoryAddress = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
const nonfungiblePositionManagerAddress = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"
const swapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

const haydenAddress = "0x11E4857Bb9993a50c685A79AFad4E6F65D518DDa"
const zeroAddress = "0x0000000000000000000000000000000000000000"


describe("AutoCompounder Tests", function () {

  let contract, nonfungiblePositionManager, factory, owner, otherAccount;

  beforeEach(async function () {
      const Contract = await ethers.getContractFactory("Compounder");
      contract = await Contract.deploy(factoryAddress, nonfungiblePositionManagerAddress, swapRouterAddress);
      await contract.deployed();

      // use interface instead of contract to test
      contract = await ethers.getContractAt("ICompounder", contract.address)

      nonfungiblePositionManager = await ethers.getContractAt("INonfungiblePositionManager", nonfungiblePositionManagerAddress);
      factory = await ethers.getContractAt("IUniswapV3Factory", factoryAddress);

      [owner, otherAccount] = await ethers.getSigners();
  });
  it("Test", async function () {
        const tokenID = 291912;
        const currentAddress = "0x5411894842e610C4D0F6Ed4C232DA689400f94A1"
        const currentContract = await ethers.getContractAt("Compounder", currentAddress);
        
        const ownerOfPosition = await currentContract.ownerOf(tokenID);
        const mainSigner = await impersonateAccountAndGetSigner(ownerOfPosition);

        await owner.sendTransaction({
            to: ownerOfPosition,
            value: ethers.utils.parseEther("1.0")
        });

        await currentContract.connect(mainSigner).withdrawToken(tokenID, contract.address, false, 0)

        await contract.connect(owner).autoCompound(
            {
                tokenId: tokenID,
                rewardConversion: 1,
                doSwap: true 
            }
        )
  });
    
  async function impersonateAccountAndGetSigner(address) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address],
    });
  
    return await ethers.getSigner(address)
  }
})