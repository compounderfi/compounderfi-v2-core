// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/access/Ownable.sol";
import "./external/openzeppelin/utils/ReentrancyGuard.sol";
import "./external/openzeppelin/utils/Multicall.sol";
import "./external/openzeppelin/token/ERC20/SafeERC20.sol";
import "./external/openzeppelin/math/SafeMath.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./external/uniswap/v3-core/libraries/TickMath.sol";
import "./external/uniswap/v3-core/libraries/FullMath.sol";
import "./external/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "./external/uniswap/v3-core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "./ICompounder.sol";
//import "forge-std/console.sol";

/// @title Compounder, an automatic reinvesting tool for uniswap v3 positions
/// @author kev1n
/** @notice 
 * Owner refers to the owner of the uniswapv3 NFT
 * Caller refers to the person who calls the AutoCompound function for the owner, which will automatically reinvest the fees for that position
 * Position refers to the uniswap v3 position/NFT
 * Protocol refers to compounder.fi, the organization who created this contract
**/

contract Compounder is ICompounder, IUniswapV3SwapCallback, ReentrancyGuard, Ownable, Multicall {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint128 constant Q96 = 2**96;
    uint256 constant Q192 = 2**192;

    //this is for the custom pool.swap logic
    bytes32 private constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    //reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%
    uint64 public constant override protocolReward = 5;

    //the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees, depending on which one they choose
    uint64 public constant override grossCallerReward = 40;

    //the max slippage allowed before reverting - slippage is a result of doing calculations on current prices and ratios, but these ratios might change after the swap is made.
    //this number is a denominator, so 200 means 1/200 or 0.5% slippage is allowed to be given back to the caller.
    //the caller is often rewarded with an extra 0.01-0.05% of unclaimed fees, and almost never as high as 0.5%+ unless for very unliquid positions, where there is high price impact for swapping
    //if you compound a position that results in more than this, say 0.6% slippage, then the transaction will revert
    uint64 public constant override maxIncreaseLiqSlippage = 200;
    
    uint160 private constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
    uint160 private constant MAX_SQRT_RATIO_MINUS_ONE = 1461446703485210103287273052203988822378723970341;

    // uniswap v3 components
    IUniswapV3Factory private immutable factory;
    INonfungiblePositionManager private immutable nonfungiblePositionManager;
    ISwapRouter private immutable swapRouter;

    mapping(address => mapping(address => uint256)) public override callerBalances; //maps a caller's address to each token's address to how much is owed to them by the protocol (rewards from calling the Compound function)
    mapping(address => uint256) public override protocolBalances; //protocol's unclaimed balances

    constructor(IUniswapV3Factory _factory, INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    event Compound(uint256 tokenId, uint256 fee0, uint256 fee1); 
    
    /**
     * @notice Compounds uniswapV3 fees for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param tokenId the tokenId being selected to compound
     * @param paidIn0 true - take token0 as the caller fee, false - take token1 as the caller fee
     * @return fee0 Amount of token0 caller recieves
     * @return fee1 Amount of token1 caller recieves
     * @dev 
     */
    function compound(uint256 tokenId, bool paidIn0) 
        override
        external
        returns (uint256 fee0, uint256 fee1) 
    {   
        CompoundState memory state = CompoundState({
            amount0: 0,
            amount1: 0,
            maxIncreaseLiqSlippage0: 0,
            maxIncreaseLiqSlippage1: 0,
            token0: address(0),
            token1: address(0),
            fee: 0,
            tickLower: 0,
            tickUpper: 0
        });

        // collect fees
        (state.amount0, state.amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
        );

        require(state.amount0 > 0 && state.amount1 > 0, "0claim");

        (, , state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, , , , , ) = 
        nonfungiblePositionManager.positions(tokenId);

        _checkApprovals(IERC20(state.token0), IERC20(state.token1));

        state.maxIncreaseLiqSlippage0 = state.amount0 / maxIncreaseLiqSlippage;
        state.maxIncreaseLiqSlippage1 = state.amount1 / maxIncreaseLiqSlippage;

        //caller earns 1/40th of their token of choice
        if (paidIn0) {
            fee0 = state.amount0 / grossCallerReward; 
            state.amount0 = state.amount0.sub(fee0);
        } else {
            fee1 = state.amount1 / grossCallerReward;
            state.amount1 = state.amount1.sub(fee1);
        }

        SwapParams memory swapParams = SwapParams(
            state.token0, 
            state.token1, 
            state.fee, 
            state.tickLower, 
            state.tickUpper, 
            state.amount0,
            state.amount1
        );

        (state.amount0, state.amount1) = 
            _swapToPriceRatio(swapParams); //returns amount of 0 and 1 after swapping

        uint256 compounded0;
        uint256 compounded1;
        // deposit liquidity into tokenId
        //sometimes this will accrue slippage, and not all of the fees will be compounded. this is because the calculations for state.amount0 and state.amount1
        //are based upon the current price ratio ratio of liquidity in the position, and both will change after the swap is made. However, this "slippage" is often negligible, and will be credited to the caller
        if (state.amount0 > 0 || state.amount1 > 0) {
            (, compounded0, compounded1) = nonfungiblePositionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    tokenId,
                    state.amount0,
                    state.amount1,
                    0,
                    0,
                    block.timestamp
                )
            );
        }

        require(state.maxIncreaseLiqSlippage0 > state.amount0 - compounded0, "slippageExceeded0");
        require(state.maxIncreaseLiqSlippage1 > state.amount1 - compounded1, "slippageExceeded1");

        if (paidIn0) {
            fee0 += state.amount0 - compounded0; //cannot underflow because state.amount0 >= compounded0
            _increaseBalanceCaller(msg.sender, state.token0, fee0);
        } else {
            fee1 += state.amount1 - compounded1; 
            _increaseBalanceCaller(msg.sender, state.token1, fee1);
        }
        
        emit Compound(tokenId, fee0, fee1);
    }

    /**
     * @notice Withdraws token balance for a caller (their fees for compounding)
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    
    //for caller only
    function withdrawBalanceCaller(address tokenAddress, address to) external override nonReentrant {
        uint256 amount = callerBalances[msg.sender][tokenAddress];
        require(amount > 0, "amount==0");
        _withdrawBalanceInternalCaller(tokenAddress, to, amount);
    }

    //for caller only
    function _withdrawBalanceInternalCaller(address tokenAddress, address to, uint256 amount) private {
        callerBalances[msg.sender][tokenAddress] = 0;

        uint256 protocolFees = amount.div(protocolReward);
        uint256 callerFees = amount.sub(protocolFees);

        SafeERC20.safeTransfer(IERC20(tokenAddress), to, callerFees);
        
        _increaseBalanceProtocol(tokenAddress, protocolFees);
    }

    //for caller only
    function _increaseBalanceCaller(address account, address tokenAddress, uint256 amount) private {
        if(amount > 0) {
            callerBalances[account][tokenAddress] = callerBalances[account][tokenAddress].add(amount);
        }
    }

    //for owner only
    function withdrawBalanceProtocol(address tokenAddress, address to) external override onlyOwner nonReentrant {
        uint256 amount = callerBalances[msg.sender][tokenAddress];
        require(amount > 0, "amount==0");
        _withdrawBalanceInternalProtocol(tokenAddress, to, amount);
    }

    //for owner only
    function _withdrawBalanceInternalProtocol(address tokenAddress, address to, uint256 amount) private {
        protocolBalances[tokenAddress] = 0;

        SafeERC20.safeTransfer(IERC20(tokenAddress), to, amount);
    }
    
    //for owner only
    function _increaseBalanceProtocol(address tokenAddress, uint256 amount) private {
        if(amount > 0) {
            protocolBalances[tokenAddress] = protocolBalances[tokenAddress].add(amount);
        }
    }

    // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
    function _swapToPriceRatio(SwapParams memory params) 
        private 
        returns (uint256 amount0, uint256 amount1) 
    {    
        //initalize memory variables
        SwapState memory state = SwapState({
            positionAmount0: 0,
            positionAmount1: 0,
            amountRatioX96: 0,
            delta0: 0,
            delta1: 0,
            priceX96: 0,
            sqrtPriceX96: 0,
            tick: 0
        });

        //initalize return variables
        amount0 = params.amount0;
        amount1 = params.amount1;
        
        // get price
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(params.token0, params.token1, params.fee));
        
        (state.sqrtPriceX96,state.tick,,,,,) = pool.slot0();
        //even though we're swapping, we don't need TWAP protection
        
        //why it is not an issue:
        // * the amount of fees in the liquidity position, assuming that it is an automated process, will never reach an amount of liquidity that is profitable for the attacker,
        // as it will be compounded efficiently. less amount in the swap -> lower price impact, generally be unprofitable for an attacker
        // * Although is possible to compound multiple positions in the same transaction, sandwich all of those transactions together, and have a greater price impact as a result
        // even if a position has a large enough amount of fees to cause price impact, it is rare that the other positions in the same pool will also have enough to cause a compounding effect on the price of the pool
        // * Users tend to gravitate towards adding liquidity to pools with a little liquidity 
        // * Users who provide meaningful % of the liquidity to small pools tend not to do so on ethereum, but chains with lower gas fees
        // Lower gas fees -> less amount needed to compound with.
        

        // calculate how much of the position needs to be converted to the other token
        // these two extremities will revert if the tick changes to be in range after the swap
        if (state.tick >= params.tickUpper) { //swap token0 to token1
            state.delta0 = amount0;
        } else if (state.tick <= params.tickLower) { //swap token1 to token0
            state.delta1 = amount1;
        } else { //figure out whether to swap token0 to token1 or token1 to token0, and how much
            (state.positionAmount0, state.positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                                                            state.sqrtPriceX96, 
                                                            TickMath.getSqrtRatioAtTick(params.tickLower), 
                                                            TickMath.getSqrtRatioAtTick(params.tickUpper), 
                                                            Q96);
                                                            

            state.amountRatioX96 = FullMath.mulDiv(state.positionAmount0, Q96, state.positionAmount1);
            uint256 amount1as0X96 = state.amountRatioX96.mul(amount1);
            uint256 amount0as0X96 = amount0.mul(Q96);
            
            state.priceX96 = FullMath.mulDiv(state.sqrtPriceX96, state.sqrtPriceX96, Q96);

            if (amount1as0X96 < amount0as0X96) {
                //swap token0 for token1
                //how much of token0 to swap is state.delta0
                state.delta0 = amount0as0X96.sub(amount1as0X96).div(FullMath.mulDiv(state.amountRatioX96, state.priceX96, Q96).add(Q96));
            } else {
                //swap token1 for token0
                //how much of token1 to swap is state.delta1
                state.delta1 = amount1as0X96.sub(amount0as0X96).div(state.amountRatioX96.add(Q192.div(state.priceX96)));
            }

        }

        PoolKey memory poolKey = PoolKey(params.token0, params.token1, params.fee);
        if (state.delta0 > 0) {
            
            (, int256 amount1Out) = pool.swap(
                address(this),
                true,
                toInt256(state.delta0),
                MIN_SQRT_RATIO_PLUS_ONE,
                abi.encode(poolKey)
            );
            
            uint256 amountOut = uint256(-amount1Out);

            amount0 = amount0.sub(state.delta0);
            amount1 = amount1.add(amountOut);
        } else {
            (int256 amount0Out,) = pool.swap(
                address(this),
                false,
                toInt256(state.delta1),
                MAX_SQRT_RATIO_MINUS_ONE,
                abi.encode(poolKey)
            );

            uint256 amountOut = uint256(-amount0Out);
            
            amount0 = amount0.add(amountOut);
            amount1 = amount1.sub(state.delta1);
        }
        
    }

    function _checkApprovals(IERC20 token0, IERC20 token1) private {
        if (token0.allowance(address(this), address(nonfungiblePositionManager)) == 0) {
            SafeERC20.safeApprove(token0, address(nonfungiblePositionManager), type(uint256).max);
        }

        if (token1.allowance(address(this), address(nonfungiblePositionManager)) == 0) {
            SafeERC20.safeApprove(token1, address(nonfungiblePositionManager), type(uint256).max);
        }
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data //data is abi encoded PoolKey
    ) external override {

        PoolKey memory poolkey = abi.decode(data, (PoolKey));

        address pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(data),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );

        require(msg.sender == pool);
        
        if (amount0Delta > 0) SafeERC20.safeTransfer(IERC20(poolkey.token0), msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) SafeERC20.safeTransfer(IERC20(poolkey.token1), msg.sender, uint256(amount1Delta));
    }

    /// @dev this function should be called by compounding bots on L2 chains only to minimize gas costs.
    /// @dev this minimizes gas costs because less calldata is rolled up to the L1, as little as 5 bytes of data versus 68 bytes when calling the compound function
    /// @dev however, it should not be called on L1s because the computation costs exceed the gas costs
    /// @dev to call this function you should send a raw transaction to this address with the following calldata:
    /// @dev "0x" + hexadecimal encoded version of the tokenId + ("01" or "00")
    /// @dev this is a total of 5 bytes of data: 4 for the tokenId and 1 for the boolean paidIn0
    /// @dev ex: calling the compound function with tokenId 48834 and paidIn0 as true should be:
    /// @dev "0x0000BEC201" -> "0x" + "0000BEC2" (48834 as hex) + "01" (true)
    fallback() external {
        uint256 tokenId;
        assembly {
            tokenId := calldataload(0)
        }

        tokenId = tokenId >> (256-4*8); //select the first 4 bytes of calldata after the selector
        bool paidIn0 = uint8(msg.data[4]) == 1; //select the last byte of calldata after the selector and the tokenId
        
        this.compound(tokenId, paidIn0);
    } 

    function toInt256(uint256 value) private pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

}