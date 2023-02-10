// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ^0.7.6;

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

    function takeBeforeMeasurements(uint256 tokenId) private returns(uint256 unclaimed0, uint256 unclaimed1, uint256 amount0before, uint256 amount1before) {
        uint256 snapshot = vm.snapshot();

        (unclaimed0, unclaimed1) = nonfungiblePositionManager.collect(
        INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
        );

        (, , , , , , , uint128 liquiditybefore, , , , ) = nonfungiblePositionManager.positions(tokenId);

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
    }

    //uint256 tokenId, bool swap
    function testPosition() public {
        uint256 tokenId = 5;
        bool paidInToken0 = true;
        
        uint256 NFPMsupply = nonfungiblePositionManager.totalSupply();
        tokenId = bound(tokenId, 0, NFPMsupply);
        require(tokenId >= 0 && tokenId < NFPMsupply);
        
        

        try nonfungiblePositionManager.ownerOf(tokenId) returns (address owner) {
            startHoax(owner);

            MeasurementsBefore memory before;
            (before.unclaimed0, before.unclaimed1, before.amount0before, before.amount1before) 
            = takeBeforeMeasurements(tokenId);

            nonfungiblePositionManager.approve(address(compounder), tokenId);
            
            nonfungiblePositionManager.safeTransferFrom(owner, address(compounder), tokenId);

            if (before.unclaimed0 == 0 || before.unclaimed1 == 0) {
                vm.expectRevert("0claim");
                compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, paidInToken0);
            } else {
                vm.stopPrank(); //call from EOA

                (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1) = compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, paidInToken0);

                (, , , , , , , uint128 liquidityafter, , , , ) = nonfungiblePositionManager.positions(tokenId);

                vm.prank(address(compounder));

                (uint256 amount0after, uint256 amount1after) = nonfungiblePositionManager.decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams(
                        tokenId, 
                        liquidityafter, 
                        0, 
                        0,
                        block.timestamp
                    )
                );

                assertEq(amount0after, compounded0 + before.amount0before);
                assertEq(amount1after, compounded1 + before.amount1before);
                
                if (paidInToken0) {
                    assertEq(fee0, before.amount0before / 5);
                } else {
                    assertEq(fee1, before.amount1before / 5);
                }

            }
        

            
        } catch (bytes memory /*lowLevelData*/) {
            
        }

        

    }


}

