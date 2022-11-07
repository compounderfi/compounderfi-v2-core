// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/token/ERC20/IERC20Metadata.sol";
import "./external/openzeppelin/token/ERC721/IERC721Receiver.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "./external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";

interface ICompounder is IERC721Receiver {

    // token movements
    event TokenDeposited(address account, uint256 tokenId);
    event TokenWithdrawn(address account, address to, uint256 tokenId);

    /// @notice Reward which is payed to compounder - less or equal to totalRewardX64
    function protocolReward() external view returns (uint64);

    /// @notice Owner of a managed NFT
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Tokens of account by index
    function accountTokens(address account, uint256 index) external view returns (uint256 tokenId);

    /**
     * @notice Returns balance of token of account for owners of positions
     * @param account Address of account
     * @param token Address of token
     * @return balance amount of token for account
     */
    function ownerBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice Returns balance of token of account for callers of positions
     * @param account Address of account
     * @param token Address of token
     * @return balance amount debted to the position at token
     */
    function callerBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice Returns balance of token of account for callers of positions
     * @param addr Address of account
     * @return openPositions an array of the open positions for addr
     */
    function addressToTokens(address addr) external view returns (uint256[] memory openPositions);



    /**
     * @notice Removes a NFT from the protocol and safe transfers it to address to
     * @param tokenId TokenId of token to remove
     * @param to Address to send to
     * @param withdrawBalances When true sends the available balances for token0 and token1 as well
     * @param data data which is sent with the safeTransferFrom call (optional)
     */
    function withdrawToken(
        uint256 tokenId,
        address to,
        bool withdrawBalances,
        bytes memory data
    ) external;

    /**
     * @notice Withdraws token balance for a address and token for an owner
     * @param token Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceOwner(address token, address to) external;

    /**
     * @notice Withdraws token balance for a address and token for a caller
     * @param token Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceCaller(address token, address to) external;

    /// @notice how reward should be converted
    enum RewardConversion { TOKEN_0, TOKEN_1 }

    /**  
        @notice the parameters for the autoCompound function
        @param tokenId the tokenId being selected to compound
        @param rewardConversion true - take token0 as the caller fee, false - take token1 as the caller fee
        @param doSwap true - caller incurs the extra gas cost for 2% rewards of their selected token fee, false - caller spends less gas but gets 1.6% rewards of their specified token
    */
    struct AutoCompoundParams {
        // tokenid to autocompound
        uint256 tokenId;
        
        // which token to convert to
        bool rewardConversion;

        // do swap - to add max amount to position (costs more gas)
        bool doSwap;
    }

     struct SwapParams {
        address token0;
        address token1;
        uint24 fee; 
        int24 tickLower; 
        int24 tickUpper; 
        uint256 amount0;
        uint256 amount1;
    }

    struct AutoCompoundState {
        uint256 amount0;
        uint256 amount1;
        uint256 excess0;
        uint256 excess1;
        address tokenOwner;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
    }

    struct SwapState {
        uint256 positionAmount0;
        uint256 positionAmount1;
        int24 tick;
        uint160 sqrtPriceX96;
        bool sell0;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        uint256 priceX96;
    }

    /**
     * @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param params Autocompound specific parameters (tokenId, ...)
     * @return fees Amount of token0 caller recieves
     * @return tokenAddress The token the fee is collected in 
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     */
    function autoCompound(AutoCompoundParams calldata params) external returns (uint256 fees, address tokenAddress, uint256 compounded0, uint256 compounded1);

    struct DecreaseLiquidityAndCollectParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
        address recipient;
    }

    /**
     * @notice Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner
     * @dev Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions
     * @param params DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 removed and collected
     * @return amount1 amount of token1 removed and collected
     */
    function decreaseLiquidityAndCollect(DecreaseLiquidityAndCollectParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Forwards collect call to NonfungiblePositionManager - can only be called by the NFT owner
     * @param params INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 collected
     * @return amount1 amount of token1 collected
     */
    function collect(INonfungiblePositionManager.CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
}