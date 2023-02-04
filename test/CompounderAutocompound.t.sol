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

    function writeTokenBalance(address who, address token, uint256 amt) internal {
        stdstore
            .target(token)
            .sig(IERC20(token).balanceOf.selector)
            .with_key(who)
            .checked_write(amt);
    }

    function _swap(bytes memory swapPath, uint256 amount, uint256 deadline) private returns (uint256 amountOut) {
        if (amount > 0) {
            amountOut = swapRouter.exactInput(
                ISwapRouter.ExactInputParams(swapPath, address(this), deadline, amount, 0)
            );
        }
    }

    function _approvals(IERC20 token0, IERC20 token1) private {
        // approve tokens once if not yet approved
        uint256 allowance0 = token0.allowance(address(this), address(nonfungiblePositionManager));
        if (allowance0 == 0) {
            SafeERC20.safeApprove(token0, address(nonfungiblePositionManager), type(uint256).max);
            SafeERC20.safeApprove(token0, address(swapRouter), type(uint256).max);
        }
        uint256 allowance1 = token1.allowance(address(this), address(nonfungiblePositionManager));
        if (allowance1 == 0) {
            SafeERC20.safeApprove(token1, address(nonfungiblePositionManager), type(uint256).max);
            SafeERC20.safeApprove(token1, address(swapRouter), type(uint256).max);
        }
    }

    function testPosition() public {
        uint256 tokenId = 5;
        uint256 NFPMsupply = nonfungiblePositionManager.totalSupply();
        tokenId = bound(tokenId, 0, NFPMsupply);
        require(tokenId >= 0 && tokenId < NFPMsupply);

        try nonfungiblePositionManager.ownerOf(tokenId) returns (address owner) {
            startHoax(owner);
            nonfungiblePositionManager.approve(address(compounder), tokenId);
            nonfungiblePositionManager.safeTransferFrom(owner, address(compounder), tokenId);
            (, , address token0, address token1, uint24 fee, , , , , , , ) = nonfungiblePositionManager.positions(tokenId);
    
            writeTokenBalance(owner, token0, 1000);
            writeTokenBalance(owner, token1, 1000);

            _approvals(IERC20(token0), IERC20(token1));
            //do a swap to ensure no revert from compounder
            _swap(
                abi.encodePacked(token0, fee, token1), 
                1000, 
                block.timestamp
            );

            _swap(
                abi.encodePacked(token1, fee, token0), 
                1000, 
                block.timestamp
            );

            compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, true);

            
        } catch (bytes memory /*lowLevelData*/) {
            
        }

        

    }


}

