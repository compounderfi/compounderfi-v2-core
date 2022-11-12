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

    /**
     * @notice reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%
     * @return the protocolReward
     */
    
    function protocolReward() external view returns (uint64);

    /**
     * @notice 
     * @return the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees  
     */
    
    function grossCallerReward() external view returns (uint64);

    /**
     * @notice  returns the owner of a compounder-managed NFT
     * @param   tokenId the tokenId being checked
     * @return  owner the owner of the tokenId
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice  Tokens of owner by index
     * @param   account the owner being checked
     * @param   index the index of the array
     * @return  tokenId the tokenId at that index for that owner
     */
    function accountTokens(address account, uint256 index) external view returns (uint256 tokenId);

    /**
     * @notice Returns balance of token of callers
     * @param account Address of account
     * @param token Address of token
     * @return balance amount debted to the position at token
     */
    function callerBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice finds the tokens an address has inside of the protocol
     * @param   addr  the address of the account
     * @return  openPositions  an array of the positions he/she has in the protocol 
     */
    function addressToTokens(address addr) external view returns (uint256[] memory openPositions);



    /**
     * @notice Removes a NFT from the protocol and safe transfers it to address to
     * @param tokenId TokenId of token to remove
     * @param to Address to send to
     * @param withdrawBalances When true sends the available balances for token0 and token1 as well
     * @param data data which is sent with the safeTransferFrom call
     */
    function withdrawToken(
        uint256 tokenId,
        address to,
        bool withdrawBalances,
        bytes memory data
    ) external;

    /**
     * @notice Withdraws token balance for a caller (their fees for compounding)
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceCaller(address tokenAddress, address to) external;

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
     * @param tokenId the tokenId being selected to compound
     * @param rewardConversion true - take token0 as the caller fee, false - take token1 as the caller fee
     * @return fee0 Amount of token0 caller recieves
     * @return fee1 Amount of token1 caller recieves
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     * @dev AutoCompound697129635642546843 saves 70 gas (optimized function selector)
     */
    function AutoCompound697129635642546843(uint256 tokenId, bool rewardConversion) external returns (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1);

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
     * @notice Forwards collect call from NonfungiblePositionManager to nft owner - can only be called by the NFT owner
     * @param params INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 collected
     * @return amount1 amount of token1 collected
     */
    function collect(INonfungiblePositionManager.CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
}