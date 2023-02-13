// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity =0.7.6;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "../src/external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import "../src/Compounder.sol";
import "../src/ICompounder.sol";


contract CompounderTest is Test {
    using stdStorage for StdStorage;
    
    ICompounder private compounder;

    INonfungiblePositionManager private nonfungiblePositionManager;
    IUniswapV3Factory private factory;
    ISwapRouter private swapRouter;
    
    
    constructor() {
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        compounder = new Compounder(factory, nonfungiblePositionManager, swapRouter);
    }

    function arrayContains(uint256[] memory arr, uint256 target) public pure returns (bool) {
        bool doesListContainElement = false;
    
        for (uint i=0; i < arr.length; i++) {
            if (target == arr[i]) {
                doesListContainElement = true;

                break;
            }
        }
        return doesListContainElement;
    }

    function takeBeforeMeasurements(uint256 tokenId) private returns(uint256 unclaimed0, uint256 unclaimed1, uint256 amount0before, uint256 amount1before, address token0, address token1) {
        uint256 snapshot = vm.snapshot();
        console.log("fail");
        (unclaimed0, unclaimed1) = nonfungiblePositionManager.collect(
        INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
        );
        console.log("fail");
        uint128 liquiditybefore;

        (, , token0, token1, , , , liquiditybefore, , , , ) = nonfungiblePositionManager.positions(tokenId);

        if (liquiditybefore == 0) {
            vm.expectRevert();
        }
        
        (amount0before, amount1before) = nonfungiblePositionManager.decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams(
            tokenId, 
            liquiditybefore, 
            0, 
            0,
            block.timestamp
        )
        );

        vm.revertTo(snapshot);
    }

    struct MeasurementsBefore {
        uint256 unclaimed0;
        uint256 unclaimed1;
        uint256 amount0before;
        uint256 amount1before;
        address token0;
        address token1;
        uint256 token0balancebefore;
        uint256 token1balancebefore;
    }

    struct MeasurementsAfter {
        uint256 fee0;
        uint256 fee1;
        uint256 compounded0;
        uint256 compounded1;
        uint256 amount0after;
        uint256 amount1after;
    }

    //uint256 tokenId, bool paidInToken0
    function testPosition() public {
        uint256 tokenId = 33256;
        bool paidInToken0 = true;
        
        uint256 NFPMsupply = nonfungiblePositionManager.totalSupply();
        tokenId = bound(tokenId, 0, NFPMsupply);
        require(tokenId >= 0 && tokenId < NFPMsupply);
        
        try nonfungiblePositionManager.ownerOf(tokenId) returns (address owner) {
            startHoax(owner); //make owner the sender

            MeasurementsBefore memory before;
            MeasurementsAfter memory afterComp;

            //take measurements before the compound happens
            (before.unclaimed0, before.unclaimed1, before.amount0before, before.amount1before, before.token0, before.token1) 
            = takeBeforeMeasurements(tokenId);


            //send tokenId to compounder
            nonfungiblePositionManager.approve(address(compounder), tokenId);
            nonfungiblePositionManager.safeTransferFrom(owner, address(compounder), tokenId);

            //did compounder successfully log the positions?
            assertEq(compounder.ownerOf(tokenId), owner);
            assertEq(arrayContains(compounder.addressToTokens(owner), tokenId), true);

            //if nothing to compound then revert
            if (before.unclaimed0 == 0 && before.unclaimed1 == 0) {
                vm.expectRevert("0claim");
                compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, paidInToken0);
            } else {
                //there's enough to compound

                vm.stopPrank(); //call from EOA instead of owner account

                //log EOA balances before compound
                before.token0balancebefore = compounder.callerBalances(msg.sender, before.token0);
                before.token1balancebefore = compounder.callerBalances(msg.sender, before.token1);

                //see what compounder returns after compound
                (afterComp.fee0, afterComp.fee1, afterComp.compounded0, afterComp.compounded1) = compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, paidInToken0);

                (, , , , , , , uint128 liquidityafter, , , , ) = nonfungiblePositionManager.positions(tokenId);
                vm.prank(address(compounder)); //prank compounder so that we can decrease liquidity
                (afterComp.amount0after, afterComp.amount1after) = nonfungiblePositionManager.decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams(
                        tokenId, 
                        liquidityafter, 
                        0, 
                        0,
                        block.timestamp
                    )
                );
                
                //the amount added to the position is equal to the amount compounder says it added (within 0.1%)
                assertApproxEqRel(afterComp.compounded0, afterComp.amount0after - before.amount0before, 0.001e18);
                assertApproxEqRel(afterComp.compounded1, afterComp.amount1after - before.amount1before, 0.001e18);
                
                //assures EOA got paid as they should've
                if (paidInToken0) {
                    assertEq(afterComp.fee0, before.unclaimed0 / compounder.grossCallerReward());
                    assertEq(before.token0balancebefore, before.token0balancebefore + afterComp.fee0);
                    assertEq(before.token1balancebefore, compounder.callerBalances(msg.sender, before.token1));
                } else {
                    assertEq(afterComp.fee1, before.unclaimed1 / compounder.grossCallerReward());
                    assertEq(before.token1balancebefore, before.token1balancebefore + afterComp.fee1);
                    assertEq(before.token0balancebefore, compounder.callerBalances(msg.sender, before.token0));
                }
                    
            }
        

            
        } catch (bytes memory /*lowLevelData*/) {
            
        }

        

    }


}

