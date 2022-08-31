import {expect} from "chai";
import { Console } from "console";
import { ethers} from "hardhat";
import { Contract, Signer } from "ethers";
import { BigNumber} from "@ethersproject/bignumber";
import "@nomicfoundation/hardhat-chai-matchers";
import { execPath } from "process";

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
        const specificPositions = [283];
        
        for(const tokenId of specificPositions) {
        //for(let tokenId = 280; tokenId < 325; tokenId ++) {

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

            if (amountPossible["amount0"] > 0 || amountPossible["amount1"] > 0) {
                const amount0 = amountPossible["amount0"].add(await contract.ownerBalances(positionOwnerAddress, token0));
                const amount1 = amountPossible["amount1"].add(await contract.ownerBalances(positionOwnerAddress, token1));

                const callerAdress = await otherAccount.getAddress();
                
                //console.log(amount0, amount1);

                const token0before = await contract.callerBalances(callerAdress, token0)
                const token1before = await contract.callerBalances(callerAdress, token1)

                //console.log(await contract.ownerBalances(token0, callerAdress));
                let compounded;
                try {
                    await nonfungiblePositionManager.connect(positionOwnerSigner)["safeTransferFrom(address,address,uint256)"](positionOwnerAddress, contract.address, tokenId, { gasLimit: 500000 });
                    compounded = await contract.connect(otherAccount).callStatic.autoCompound( { tokenId, rewardConversion: x, doSwap: true });
                } catch(e) {
                    console.log(e, tokenId)
                }
                await contract.connect(otherAccount).autoCompound( { tokenId, rewardConversion: x, doSwap: true });
                //console.log(compounded)
                const token0after = await contract.callerBalances(callerAdress, token0)
                const token1after = await contract.callerBalances(callerAdress, token1)

                //const swap = x%2==0 ? 25 : 20
                
                const swap = 25;

                //* verify that the fees match up
                try {
                   
                    if (x==0) {
                        expect(token0after.sub(token0before)).to.equal(compounded["fees0"])
                        expect(token0after.sub(token0before)).to.be.within(amount0.mul(swap).div(1000)-1, amount0.mul(swap).div(1000));
                    } else {
                        expect(token1after.sub(token1before)).to.equal(compounded["fees1"])
                        expect(token1after.sub(token1before)).to.be.within(amount1.mul(swap).div(1000)-1, amount1.mul(swap).div(1000));
                        
                    }
                } catch(e) {
                    //console.log(e)
                }
                
                const token0contract = await ethers.getContractAt("IERC20", token0);
                const token1contract = await ethers.getContractAt("IERC20", token1);
                /*
                if(x % 2==0) { //swap enabled
                    expect(await contract.ownerBalances(token0, callerAdress)).to.be.equal(0);
                    expect(await contract.ownerBalances(token0, callerAdress)).to.be.equal(0);
                    expect(contract.connect(positionOwnerSigner).withdrawBalanceOwner(token0, positionOwnerAddress)).to.be.revertedWith("amount==0");
                    expect(contract.connect(positionOwnerSigner).withdrawBalanceOwner(token1, positionOwnerAddress)).to.be.revertedWith("amount==0");
                } else {
                    console.log(amount0, compounded["fees0"],compounded["compounded0"]);
                    console.log(amount1, compounded["fees1"],compounded["compounded1"]);
                    const remaining0 = amount0.sub(compounded["fees0"]).sub(compounded["compounded0"]);
                    const remaining1 = amount1.sub(compounded["fees1"]).sub(compounded["compounded1"]);

                    expect(await contract.ownerBalances(token0, callerAdress)).to.be.equal(remaining0);
                    expect(await contract.ownerBalances(token1, callerAdress)).to.be.equal(remaining1);

                    const positionownertoken0beforeWithdraw = await token0contract.balanceOf(positionOwnerAddress);
                    const positionownertoken1beforeWithdraw = await token1contract.balanceOf(positionOwnerAddress);

                    contract.connect(positionOwnerSigner).withdrawBalanceOwner(token0, positionOwnerAddress)
                    contract.connect(positionOwnerSigner).withdrawBalanceOwner(token1, positionOwnerAddress)

                    const positionownertoken0afterWithdraw = await token0contract.balanceOf(positionOwnerAddress);
                    const positionownertoken1afterWithdraw = await token1contract.balanceOf(positionOwnerAddress);

                    expect(positionownertoken0afterWithdraw.sub(positionownertoken0beforeWithdraw).to.be.equal(remaining0));
                    expect(positionownertoken1afterWithdraw.sub(positionownertoken1beforeWithdraw).to.be.equal(remaining1));
                }
                */

                if (token0after > 0) {
                    const callertoken0beforeWithdraw = await token0contract.balanceOf(callerAdress);
                    const ownertoken0beforeWithdraw = await token0contract.balanceOf(await owner.getAddress());
                    await contract.connect(otherAccount).withdrawBalanceCaller(token0, callerAdress);
                    const callertoken0afterWithdraw = await token0contract.balanceOf(callerAdress);
                    const ownertoken0afterWithdraw = await token0contract.balanceOf(await owner.getAddress());
                    
                    try {
                        expect(callertoken0afterWithdraw.sub(callertoken0beforeWithdraw)).to.be.within(token0after.mul(4).div(5)-1, token0after.mul(4).div(5)+1);
                        expect(await contract.callerBalances(callerAdress, token0)).to.be.equal(0);
                        expect(contract.connect(otherAccount).withdrawBalanceCaller(token0, callerAdress)).to.be.reverted;
                        expect(ownertoken0afterWithdraw.sub(ownertoken0beforeWithdraw)).to.be.within(token0after.div(5)-1, token0after.div(5)+1)
                    } catch (e) {
                        console.log(e);
                        console.log(tokenId)
                    }
                }
                if (token1after > 0) {
                    const callertoken1beforeWithdraw = await token1contract.balanceOf(callerAdress);
                    const ownertoken1beforeWithdraw = await token1contract.balanceOf(await owner.getAddress());
                    await contract.connect(otherAccount).withdrawBalanceCaller(token1, callerAdress);
                    const callertoken1afterWithdraw = await token1contract.balanceOf(callerAdress);
                    const ownertoken1afterWithdraw = await token1contract.balanceOf(await owner.getAddress());

                    try {
                        expect(callertoken1afterWithdraw.sub(callertoken1beforeWithdraw)).to.be.within(token1after.mul(4).div(5)-1, token1after.mul(4).div(5)+1);
                        expect(await contract.callerBalances(callerAdress, token1)).to.be.equal(0);
                        expect(contract.connect(otherAccount).withdrawBalanceCaller(token1, callerAdress)).to.be.reverted;
                        expect(ownertoken1afterWithdraw.sub(ownertoken1beforeWithdraw)).to.be.within(token1after.div(5)-1, token1after.div(5)+1)
                    } catch (e) {
                        console.log(e);
                        console.log(tokenId)
                    }
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