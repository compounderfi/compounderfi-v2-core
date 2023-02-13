// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

//import "../src/Compounder.sol";
import "./MyERC20.sol";
import "@uniswap/v3-periphery/contracts/base/PoolInitializer.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract UniswapHelper {
   
    /// @notice Calls the mint function defined in periphery, mints the same amount of each token. For this example we are providing 1000 DAI and 1000 USDC in liquidity
    /// @return tokenId The id of the newly minted ERC721
    /// @return liquidity The amount of liquidity for the position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mintNewPosition(address nonfungiblePositionManager)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        MyERC20 token0 = new MyERC20();
        MyERC20 token1 = new MyERC20();
        token0.mint(address(this), 5000);
        token1.mint(address(this), 5000);

        PoolInitializer initalizer = new PoolInitializer();

        initalizer.createAndInitializePoolIfNecessary(token0, token1, 3000, 1000);

        // For this example, we will provide equal amounts of liquidity in both assets.
        // Providing liquidity in both assets means liquidity will be earning fees and is considered in-range.
        uint256 amount0ToMint = 1000;
        uint256 amount1ToMint = 1000;

        // Approve the position manager
        token0.approve(address(nonfungiblePositionManager), amount0ToMint);
        token1.approve(address(nonfungiblePositionManager), amount0ToMint);

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: 3000,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
    }
}