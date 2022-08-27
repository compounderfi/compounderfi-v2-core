const { BigNumber } = require("@ethersproject/bignumber");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { boolean } = require("hardhat/internal/core/params/argumentTypes");

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
  it("Test random positions", async function () {
    const minBalanceToSafeTransfer = BigNumber.from("500000").mul(await ethers.provider.getGasPrice()) 
    
    const positionIndices = [1, 4, 5, 6, 7, 8, 10];
    let feesToken = 0;
    let swap = false;
    for(let i of positionIndices) {
        const tokenId = await nonfungiblePositionManager.tokenByIndex(i);
        const ownerAddress = await nonfungiblePositionManager.ownerOf(tokenId);
        await owner.sendTransaction({
            to: ownerAddress,
            value: ethers.utils.parseEther("1.0")
        });
        const ownerSigner = await impersonateAccountAndGetSigner(ownerAddress)
        await nonfungiblePositionManager.connect(ownerSigner)[["safeTransferFrom(address,address,uint256)"]](ownerAddress, contract.address, tokenId, { gasLimit: 500000 });
        console.log(tokenId, feesToken, swap)
        await contract.autoCompound( { tokenId, rewardConversion: feesToken, doSwap: swap });


        if (feesToken == 0 ) {
            swap = !swap;
        } else {
            feesToken = (feesToken + 1) % 2;
        }
      
    }
  })
  
    
  async function impersonateAccountAndGetSigner(address) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address],
    });
  
    return await ethers.getSigner(address)
  }
})