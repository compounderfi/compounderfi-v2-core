import chai, { expect } from "chai";
import { Console } from "console";
import { ethers} from "hardhat";
import { Contract, Signer } from "ethers";
import { BigNumber} from "@ethersproject/bignumber";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

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
    let contract: Contract;
    let nonfungiblePositionManager: Contract;
    let factory: Contract;
    let owner: Signer;
    let otherAccount: Signer;
  
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
      let x = 0;
      for(let tokenId = 3; tokenId < 4; tokenId ++) {
          const ownerAddress = await nonfungiblePositionManager.ownerOf(tokenId);
          await owner.sendTransaction({
              to: ownerAddress,
              value: ethers.utils.parseEther("1.0")
          });
          const ownerSigner = await ethers.getImpersonatedSigner(ownerAddress);
          const amountPossible = await nonfungiblePositionManager.connect(ownerSigner).callStatic.collect(
            [tokenId, ownerAddress, 5, 5]
          )
  
          const amount0 = amountPossible["amount0"];
          const amount1 = amountPossible["amount1"];
          if (amount0 > 0 || amount1 > 0) {
            await nonfungiblePositionManager.connect(ownerSigner)["safeTransferFrom(address,address,uint256)"](ownerAddress, contract.address, tokenId, { gasLimit: 500000 });
            await contract.autoCompound( { tokenId, rewardConversion: x, doSwap: x%2==0 });
            
            x = (x + 1) % 2
          } else {
            console.log(`position ${tokenId} doesn't have enough to be compounded`)
          }
  
      }
    })
  
    it("test position transfer and withdrawal", async function () {
      const nftId1 = 1
      const nftId2 = 5
      const haydenSigner = await ethers.getImpersonatedSigner(haydenAddress);
        
      await nonfungiblePositionManager.connect(haydenSigner)["safeTransferFrom(address,address,uint256)"](haydenAddress, contract.address, nftId1);
      await nonfungiblePositionManager.connect(haydenSigner)["safeTransferFrom(address,address,uint256)"](haydenAddress, contract.address, nftId2);
  
      const nftOwner = await contract.ownerOf(nftId1);
      const nftStored1 = await contract.accountTokens(haydenAddress, 0);
      const nftStored2 = await contract.accountTokens(haydenAddress, 1);
  
      const openPositions = await contract.addressToTokens(haydenAddress);
  
      const position1 = openPositions[0].toNumber();
      const position2 = openPositions[1].toNumber();
  
      // expect owner to match og
      expect(nftOwner).to.equal(haydenAddress);
      expect(nftStored1.toNumber()).to.equal(nftId1);
      expect(nftStored2.toNumber()).to.equal(nftId2);
  
      expect(position1).to.equal(nftId1);
      expect(position2).to.equal(nftId2);
      // withdraw token
      await contract.connect(haydenSigner).withdrawToken(nftId1, haydenAddress, true, 0);
  
      // token no longer in contract
      expect(await contract.callStatic.ownerOf(nftId1)).to.equal(zeroAddress);
  
      
    })
    
      

})