// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "forge-std/Test.sol";
import "../src/external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "../src/Compounder.sol";
import "../src/ICompounder.sol";

contract CompounderTest is Test {

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
    /*
    function testDeposit(uint256 tokenId) public {
        uint256 NFPMsupply = nonfungiblePositionManager.totalSupply();
        tokenId = bound(tokenId, 0, NFPMsupply);
        require(tokenId >= 0 && tokenId < NFPMsupply);

        try nonfungiblePositionManager.ownerOf(tokenId) returns (address owner) {
            hoax(owner);
            nonfungiblePositionManager.safeTransferFrom(owner, address(compounder), tokenId);
            compounder.AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(tokenId, true);

            
        } catch (bytes memory ) {
            
        }
    }
    */
    


}

