import {expect} from "chai";
import { Console } from "console";
import { ethers} from "hardhat";
import { Contract, Signer } from "ethers";
import { BigNumber} from "@ethersproject/bignumber";
import "@nomicfoundation/hardhat-chai-matchers";

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
        //const specificPositions = [98, 96, 94];
        
        //for(const tokenId of specificPositions) {
        for(let tokenId = 10; tokenId < 100; tokenId ++) {

            const positionOwnerAddress = await nonfungiblePositionManager.ownerOf(tokenId);
            await owner.sendTransaction({
                to: positionOwnerAddress,
                value: ethers.utils.parseEther("1.0")
            });
            const positionOwnerSigner = await ethers.getImpersonatedSigner(positionOwnerAddress);
            const amountPossible = await nonfungiblePositionManager.connect(positionOwnerSigner).callStatic.collect(
                [tokenId, positionOwnerAddress, BigNumber.from("340282366920938463463374607431768211455"), BigNumber.from("340282366920938463463374607431768211455")]
            )
            const pos = await nonfungiblePositionManager.callStatic.positions(tokenId);
            const token0 = pos["token0"];
            const token1 = pos["token1"];

            
            const amount0 = amountPossible["amount0"].add(await contract.ownerBalances(positionOwnerAddress, token0));
            const amount1 = amountPossible["amount1"].add(await contract.ownerBalances(positionOwnerAddress, token1));

            if (amount0 > 0 || amount1 > 0) {
                
                //console.log(amount0, amount1);

                const token0before = await contract.callerBalances(await owner.getAddress(), token0)
                const token1before = await contract.callerBalances(await owner.getAddress(), token1)

                await nonfungiblePositionManager.connect(positionOwnerSigner)["safeTransferFrom(address,address,uint256)"](positionOwnerAddress, contract.address, tokenId, { gasLimit: 500000 });
                await contract.connect(owner).autoCompound( { tokenId, rewardConversion: x, doSwap: x==0 });
                
                const token0after = await contract.callerBalances(await owner.getAddress(), token0)
                const token1after = await contract.callerBalances(await owner.getAddress(), token1)

                const swap = x%2==0 ? 25 : 20
                //const swap = 0.02;

                try {
                   
                    if (x==0) {
                        expect(token0after.sub(token0before)).to.be.within(amount0.mul(swap).div(1000)-1, amount0.mul(swap).div(1000));
                    } else {
                        expect(token1after.sub(token1before)).to.be.within(amount1.mul(swap).div(1000)-1, amount1.mul(swap).div(1000));
                        
                    }
                } catch(e) {
                    console.log(e)
                }

                x = (x + 1) % 2
            } else {
                //console.log(`position ${tokenId} doesn't have enough to be compounded`)
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

        const openPositions = await contract.addressToTokens(haydenAddress);

        const position1 = openPositions[0]
        const position2 = openPositions[1]

        // expect owner to match og
        expect(await contract.ownerOf(nftId1)).to.be.equal(haydenAddress);
        expect(await contract.accountTokens(haydenAddress, 0)).to.equal(nftId1);
        expect(await contract.accountTokens(haydenAddress, 1)).to.equal(nftId2);

        expect(position1).to.equal(nftId1);
        expect(position2).to.equal(nftId2);

        // withdraw token
        await contract.connect(haydenSigner).withdrawToken(nftId1, haydenAddress, true, 0);

        // token no longer in contract
        await expect(contract.connect(haydenSigner).withdrawToken(nftId1, haydenAddress, true, 0)).to.be.revertedWith("!owner");
        expect(await contract.callStatic.ownerOf(nftId1)).to.equal(zeroAddress);
        const tokenLeft = (await contract.accountTokens(haydenAddress, 0));

        expect(tokenLeft).to.equal(nftId2);

        const remainingPositions = await contract.addressToTokens(haydenAddress);
        const remain = remainingPositions[0];

        expect(remain).to.equal(nftId2);

        //withdraw other token
        await contract.connect(haydenSigner).withdrawToken(nftId2, haydenAddress, true, 0); //none left
        await expect(contract.connect(haydenSigner).withdrawToken(nftId2, haydenAddress, true, 0)).to.be.revertedWith("!owner");
        expect(await contract.callStatic.ownerOf(nftId2)).to.equal(zeroAddress);

        await expect(contract.accountTokens(haydenAddress, 0)).to.be.reverted;
        await expect(contract.accountTokens(haydenAddress, 1)).to.be.reverted;
        
        expect(await contract.addressToTokens(haydenAddress)).to.deep.equal([]);

    })


    
      

})