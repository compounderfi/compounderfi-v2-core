// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity =0.7.6;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "../src/external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import "../src/Compounder.sol";
import "../src/ICompounder.sol";
import "../src/external/pancakeswap/IMasterChefV3.sol";

contract CompounderTest is Test {
    using stdStorage for StdStorage;
        
    Compounder private compounder;

    INonfungiblePositionManager private nonfungiblePositionManager;
    IUniswapV3Factory private factory;
    ISwapRouter private swapRouter;
    
    
    constructor() {
        factory = IUniswapV3Factory(0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865);
        nonfungiblePositionManager = INonfungiblePositionManager(0x46A15B0b27311cedF172AB29E4f4766fbE7F4364);
        swapRouter = ISwapRouter(0x13f4EA83D0bd40E75C8222255bc855a974568Dd4);
        address deployer = 0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9;
        compounder = new Compounder(factory, nonfungiblePositionManager, swapRouter, deployer);
    }

    struct MeasurementsBefore {
        uint256 unclaimed0;
        uint256 unclaimed1;
        uint256 amount0before;
        uint256 amount1before;
        uint256 token0balancebefore;
        uint256 token1balancebefore;
        uint256 liquidity;
    }

    struct MeasurementsAfter {
        uint256 fee0;
        uint256 fee1;
        uint256 amount0after;
        uint256 amount1after;
        uint256 liqcompounded;
        uint256 slippage0;
        uint256 slippage1;
    }

    struct PositionData {
        address token0;
        address token1;
        IUniswapV3Pool pool;
    }
    
    
    //uint256 tokenId, bool paidInToken0
    function testPosition() public {
        
        uint256 tokenId = 41000;
        bool paidInToken0 = true;
        
        /*
        
        uint256 NFPMsupply = nonfungiblePositionManager.totalSupply();
        tokenId = bound(tokenId, 375000, NFPMsupply);
        require(tokenId >= 375000 && tokenId < NFPMsupply);
        */

        IMasterChefV3 masterchef = IMasterChefV3(0x556B9306565093C855AEA9AE92A594704c2Cd59e);
        try nonfungiblePositionManager.ownerOf(tokenId) returns (address positionOwner) {
            startHoax(positionOwner); //make owner the sender

            MeasurementsBefore memory before;
            MeasurementsAfter memory afterComp;
            PositionData memory data;
            //take measurements before the compound happens
            
            (before.liquidity, before.unclaimed0, before.unclaimed1, before.amount0before, before.amount1before, data.token0, data.token1, data.pool) 
            = _takeBeforeMeasurements(tokenId);
            
            

            //approve tokenId to compounder
            nonfungiblePositionManager.safeTransferFrom(positionOwner, address(compounder), tokenId);

            //if nothing to compound then revert
            if (before.unclaimed0 == 0 || before.unclaimed1 == 0) {
                vm.expectRevert("0claim");
                compounder.compound(tokenId, paidInToken0);
            } else {//there's enough to compound

                //log EOA balances before compound
                before.token0balancebefore = compounder.callerBalances(address(this), data.token0);
                before.token1balancebefore = compounder.callerBalances(address(this), data.token1);


                //see what compounder returns after compound
                (afterComp.fee0, afterComp.fee1) 
                = compounder.compound(tokenId, paidInToken0);
                
                (, , , , , , , uint128 liquidityafter, , , , ) = nonfungiblePositionManager.positions(tokenId);

                uint256 snapshot = vm.snapshot();

                (afterComp.amount0after, afterComp.amount1after) = nonfungiblePositionManager.decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams(
                        tokenId, 
                        liquidityafter, 
                        0, 
                        0,
                        block.timestamp
                    )
                );
                
                vm.revertTo(snapshot);

                //assertEq(afterComp.liqcompounded, liquidityafter - before.liquidity, "liquidity actually added");
                //console.log(afterComp.slippage0 * 100000000);
                //console.log(afterComp.slippage1 * 100000000);
                //assures EOA got paid as they should've

                /*
                vm.writeLine("./output.txt", uint2str(tokenId));
                vm.writeLine("./output.txt", "slippage0");
                */
                //if ((( afterComp.slippage0 * 100000000) / before.unclaimed0) != 0)
                //vm.writeLine("./output.txt", uint2str(( afterComp.slippage0 * 100000000) / before.unclaimed0));
                /*
                vm.writeLine("./output.txt", "slippage1");
                */
                //if ((( afterComp.slippage1 * 100000000) / before.unclaimed1) != 0)
                //vm.writeLine("./output.txt", uint2str(( afterComp.slippage1 * 100000000) / before.unclaimed1));
                /*
                vm.writeLine("./output.txt", "-----------");
                */
                if (paidInToken0) {
                    //vm.writeLine("./output.txt", uint2str(tokenId));

                    assertGe(afterComp.fee0, before.unclaimed0 / compounder.grossCallerReward(), "fee0 should be greater than 2.5%");
                    assertLe(afterComp.fee0, before.unclaimed0 / 33, "fee0 should be less than 3%");
                    assertGe(compounder.callerBalances(positionOwner, data.token0), before.token0balancebefore + afterComp.fee0, "callerbalances added to right token0");         
                    assertEq(before.token1balancebefore, compounder.callerBalances(positionOwner, data.token1), "no token1 added");

                    //determine how much of token0 the positionOwner already had
                    uint256 positionOwnerToken0before = IERC20(data.token0).balanceOf(positionOwner);
                    uint256 balanceCaller0Before = compounder.callerBalances(positionOwner, data.token0);
                    uint256 balanceCaller1Before = compounder.callerBalances(positionOwner, data.token1);
                    compounder.withdrawBalanceCaller(data.token0, positionOwner);

                    uint256 positionOwnerToken0After = IERC20(data.token0).balanceOf(positionOwner);
                    uint256 balanceCaller0After = compounder.callerBalances(positionOwner, data.token0);
                    uint256 balanceCaller1After = compounder.callerBalances(positionOwner, data.token1);
                    uint256 gain0 = positionOwnerToken0After - positionOwnerToken0before;
                    uint256 protocolReward = afterComp.fee0 / compounder.protocolReward();

                    assertEq(balanceCaller1Before - balanceCaller1After, 0, "balanceCaller1 should be equal to 0");
                    assertEq(balanceCaller0Before - balanceCaller0After, afterComp.fee0, "balanceCaller0 should be equal to fee0");
                    assertEq(gain0, afterComp.fee0 - protocolReward, "gain0 should be equal to fee0 - protocolReward");
                    assertEq(compounder.protocolBalances(data.token0), afterComp.fee0 - gain0, "protocolBalances should be equal to fee0 - gain0");
                    
                    //prank the owner of the contract
                    vm.stopPrank();
                    startHoax(compounder.owner());

                    uint256 protocolOwnerToken0before = IERC20(data.token0).balanceOf(compounder.owner());
                    compounder.withdrawBalanceProtocol(data.token0, compounder.owner());
                    uint256 protocolOwnerToken0after = IERC20(data.token0).balanceOf(compounder.owner());
                    assertEq(protocolOwnerToken0after - protocolOwnerToken0before, protocolReward, "protocolOwner should get protocolReward");

                } else {
                    //vm.writeLine("./output.txt", uint2str(tokenId));

                    assertGe(afterComp.fee1, before.unclaimed1 / compounder.grossCallerReward(), "fee1 should be greater than 2.5%");
                    assertLe(afterComp.fee1, before.unclaimed1 / 33, "fee1 should be less than 3%");
                    assertGe(compounder.callerBalances(positionOwner, data.token1), before.token1balancebefore + afterComp.fee1, "callerbalances added to right token1");
                    assertEq(before.token0balancebefore, compounder.callerBalances(positionOwner, data.token0), "no token0 added");
                    
                    //determine how much of token1 the positionOwner already had
                    uint256 positionOwnerToken1before = IERC20(data.token1).balanceOf(positionOwner);
                    uint256 balanceCaller1Before = compounder.callerBalances(positionOwner, data.token1);
                    uint256 balanceCaller0Before = compounder.callerBalances(positionOwner, data.token0);
                    compounder.withdrawBalanceCaller(data.token1, positionOwner);

                    uint256 positionOwnerToken1After = IERC20(data.token1).balanceOf(positionOwner);
                    uint256 balanceCaller1After = compounder.callerBalances(positionOwner, data.token1);
                    uint256 balanceCaller0After = compounder.callerBalances(positionOwner, data.token0);
                    uint256 gain1 = positionOwnerToken1After - positionOwnerToken1before;
                    uint256 protocolReward = afterComp.fee1 / compounder.protocolReward();

                    assertEq(balanceCaller0Before - balanceCaller0After, 0, "balanceCaller0 should be equal to 0");
                    assertEq(balanceCaller1Before - balanceCaller1After, afterComp.fee1, "balanceCaller1 should be equal to fee1");
                    assertEq(gain1, afterComp.fee1 - protocolReward, "gain1 should be equal to fee1 - protocolReward");
                    assertEq(compounder.protocolBalances(data.token1), afterComp.fee1 - gain1, "protocolBalances should be equal to fee1 - gain1");

                    //prank the owner of the contract
                    vm.stopPrank();
                    startHoax(compounder.owner());

                    uint256 protocolOwnerToken1before = IERC20(data.token1).balanceOf(compounder.owner());
                    compounder.withdrawBalanceProtocol(data.token1, compounder.owner());
                    uint256 protocolOwnerToken1after = IERC20(data.token1).balanceOf(compounder.owner());
                    assertEq(protocolOwnerToken1after - protocolOwnerToken1before, protocolReward, "protocolOwner should get protocolReward");

                }


            }
        

            
        } catch (bytes memory) {
            
        }

        

    }
    function _takeBeforeMeasurements(uint256 tokenId) private returns(uint128 liquiditybefore, uint256 unclaimed0, uint256 unclaimed1, uint256 amount0before, uint256 amount1before, address token0, address token1, IUniswapV3Pool pool) {
        uint256 snapshot = vm.snapshot();

        (unclaimed0, unclaimed1) = nonfungiblePositionManager.collect(
        INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
        );
        uint24 fee;
        (, , token0, token1, fee, , , liquiditybefore, , , , ) = nonfungiblePositionManager.positions(tokenId);

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
        pool = IUniswapV3Pool(factory.getPool(token0, token1, fee));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}

