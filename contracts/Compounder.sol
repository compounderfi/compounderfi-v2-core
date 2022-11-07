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

import "./ICompounder.sol";
//import "hardhat/console.sol";

/// @title Compounder, an automatic reinvesting tool for uniswap v3 positions
/// @author kev1n
/** @notice 
 * Owner refers to the owner of the uniswapv3 NFT
 * Caller refers to the person who calls the AutoCompound function for the owner, which will automatically reinvest the fees for that position
 * Position refers to the uniswap v3 position/NFT
 * Protocol refers to compounder.fi, the organization who created this contract
**/
contract Compounder is ICompounder, ReentrancyGuard, Ownable, Multicall {

    using SafeMath for uint256;

    uint128 constant Q96 = 2**96;
    uint256 constant Q192 = 2**192;

    // max positions
    uint32 constant public MAX_POSITIONS_PER_ADDRESS = 100;

    //protocol takes a fifth of what Callers make; callers get 1.6% for no-swap compounds and 2% for swaps
    uint64 public constant override protocolReward = 5;

    // uniswap v3 components
    IUniswapV3Factory private immutable factory;
    INonfungiblePositionManager private immutable nonfungiblePositionManager;
    ISwapRouter private immutable swapRouter;

    mapping(uint256 => address) public override ownerOf; //maps a tokenID to its owner - when sent to this contract to be autocompounded
    mapping(address => uint256[]) public override accountTokens; //maps an address to all of the tokens it owns 
    mapping(address => mapping(address => uint256)) public override callerBalances; //maps a caller's address to each token's address to how much is owed to them by the protocol (rewards from calling the autocompound function)
    mapping(address => mapping(address => uint256)) public override ownerBalances; //maps a owner's address to each token's address to how much is owed to them by the protocol (excess tokens from the autocompound function are given back to the owner of the position)

    constructor(IUniswapV3Factory _factory, INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }
    
    /**
     * @notice modifier that makes sure the owner of a position is the sender
     * @param tokenId the tokenId of the position being compared
     */
    modifier onlyPositionOwner(uint256 tokenId) {
        require(ownerOf[tokenId] == msg.sender, "!owner");
        _;
    }

    /**
     * @notice finds the tokens an address has inside of the protocol
     * @param   addr  the address of the account
     * @return  uint256[]  an array of the positions he/she has in the protocol 
     */
    function addressToTokens(address addr) external view override returns (uint256[] memory) {
        return accountTokens[addr];
    }
    

    
    /**
     * @notice  When receiving a Uniswap V3 NFT, deposits token with `from` as owner
     * @param   tokenId  the tokenId being deposited into the protocol
     * @return  bytes4  openzeppelin: "It must return its Solidity selector to confirm the token transfer"
     */
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(nonfungiblePositionManager), "!univ3 pos");

        _addToken(tokenId, tx.origin); //use tx.origin to support multicall sending of multiple positions in one txn
        emit TokenDeposited(tx.origin, tokenId);
        return this.onERC721Received.selector;
    }

    event AutoCompound();
    /**
     * @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param params Autocompound specific parameters
     * @return fees Amount of fees collected by the protocol AND caller
     * @return tokenAddress Token the fees are in
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     */
    function autoCompound(AutoCompoundParams memory params) 
        override 
        external
        returns (uint256 fees, address tokenAddress, uint256 compounded0, uint256 compounded1) 
    {   
        AutoCompoundState memory state;
        state.tokenOwner = ownerOf[params.tokenId];

        require(state.tokenOwner != address(0), "!found");

        // collect fees
        (state.amount0, state.amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(params.tokenId, address(this), type(uint128).max, type(uint128).max)
        );

        require(state.amount0 > 0 || state.amount1 > 0);


        if(params.doSwap) { //gas optimization to load less slots when they're not needed
            (, , state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, , , , , ) = 
            nonfungiblePositionManager.positions(params.tokenId);
        } else {
            (, , state.token0, state.token1, , , , , , , , ) = 
            nonfungiblePositionManager.positions(params.tokenId);
        }
    
        state.excess0 = ownerBalances[state.tokenOwner][state.token0];
        state.excess1 = ownerBalances[state.tokenOwner][state.token1];

        if (state.excess0 > 0) { //gas optimization - boolean comparision is less expensive than adding
            state.amount0 = state.amount0.add(state.excess0);
        }
        if (state.excess1 > 0) {
            state.amount1 = state.amount1.add(state.excess1);
        }
        
        if (params.doSwap) {

            //caller chooses fee of their choice - they earn 1/40th when incurring the
            //extra gas cost of swapping but only 1/50th when not swapping
            if (params.rewardConversion) {
                fees = state.amount0 / 40; 
                state.amount0 = state.amount0.sub(fees);
            } else {
                fees = state.amount1 / 40;
                state.amount1 = state.amount1.sub(fees);
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
            

        } else {
            if (params.rewardConversion) {
                fees = state.amount0 / 50;
                state.amount0 = state.amount0.sub(fees);
            } else {
                fees = state.amount1 / 50;
                state.amount1 = state.amount1.sub(fees);
            }
        }
        //console.log(state.amount0, state.amount1);
        // deposit liquidity into tokenId
        if (state.amount0 > 0 || state.amount1 > 0) {
            (, compounded0, compounded1) = nonfungiblePositionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    params.tokenId,
                    state.amount0,
                    state.amount1,
                    0,
                    0,
                    block.timestamp
                )
            );
        }

        if (params.doSwap) {
            if (state.excess0 > 0) { //gas optimization
                ownerBalances[state.tokenOwner][state.token0] = 0; //assume there's none left to save save (there is a negigble amount)
            }
            if (state.excess1 > 0) {
                ownerBalances[state.tokenOwner][state.token1] = 0;
            }
        } else {
            ownerBalances[state.tokenOwner][state.token0] = state.amount0.sub(compounded0); //owner gets the remaining balance
            ownerBalances[state.tokenOwner][state.token1] = state.amount1.sub(compounded1);
        }

        if (params.rewardConversion) {
            tokenAddress = state.token0;
            _increaseBalanceCaller(msg.sender, state.token0, fees);
            
        } else {
            tokenAddress = state.token1;
            _increaseBalanceCaller(msg.sender, state.token1, fees);
        }
        emit AutoCompound();
    }

    /**
     * @notice Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner
     * @dev Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions
     * @param params DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 removed and collected
     * @return amount1 amount of token1 removed and collected
     */
    function decreaseLiquidityAndCollect(DecreaseLiquidityAndCollectParams calldata params) 
        override 
        external  
        nonReentrant
        onlyPositionOwner(params.tokenId)
        returns (uint256 amount0, uint256 amount1) 
    {
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(
                params.tokenId, 
                params.liquidity, 
                params.amount0Min, 
                params.amount1Min,
                params.deadline
            )
        );

        INonfungiblePositionManager.CollectParams memory collectParams = 
            INonfungiblePositionManager.CollectParams(
                params.tokenId, 
                params.recipient, 
                LiquidityAmounts.toUint128(amount0), 
                LiquidityAmounts.toUint128(amount1)
            );

        nonfungiblePositionManager.collect(collectParams);
    }

    /**
     * @notice Forwards collect call to NonfungiblePositionManager - can only be called by the NFT owner
     * @param params INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 collected
     * @return amount1 amount of token1 collected
     */
    function collect(INonfungiblePositionManager.CollectParams calldata params) 
        override 
        external
        nonReentrant
        onlyPositionOwner(params.tokenId)
        returns (uint256 amount0, uint256 amount1) 
    {
        return nonfungiblePositionManager.collect(params);
    }

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
    ) external override nonReentrant onlyPositionOwner(tokenId) {
        require(to != address(this), "to==this");

         if (withdrawBalances) {// fine to withdraw before because the function is nonReetrant
            nonfungiblePositionManager.collect(
                INonfungiblePositionManager.CollectParams(tokenId, to, type(uint128).max, type(uint128).max)
            );
            
            (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

            _withdrawFullBalancesInternalOwner(token0, token1, to);
        }

        _removeToken(msg.sender, tokenId);
        nonfungiblePositionManager.safeTransferFrom(address(this), to, tokenId, data);
        emit TokenWithdrawn(msg.sender, to, tokenId);
    }

    /**
     * @notice Withdraws token balance for a token owner and withdraws token
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */

    //for owner only
    function withdrawBalanceOwner(address tokenAddress, address to) external override nonReentrant {
        uint256 amount = ownerBalances[msg.sender][tokenAddress];
        require(amount > 0, "amount==0");
        _withdrawBalanceInternalOwner(tokenAddress, to, amount);
    }

    //for caller only
    function withdrawBalanceCaller(address tokenAddress, address to) external override nonReentrant {
        uint256 amount = callerBalances[msg.sender][tokenAddress];
        require(amount > 0, "amount==0");
        _withdrawBalanceInternalCaller(tokenAddress, to, amount);
    }

    //for caller only
    function _increaseBalanceCaller(address account, address tokenAddress, uint256 amount) private {
        if(amount > 0) {
            callerBalances[account][tokenAddress] = callerBalances[account][tokenAddress].add(amount);
        }
    }

    //for owner only
    function _withdrawFullBalancesInternalOwner(address token0, address token1, address to) private {
        uint256 balance0 = ownerBalances[msg.sender][token0];
        if (balance0 > 0) {
            _withdrawBalanceInternalOwner(token0, to, balance0);
        }
        uint256 balance1 = ownerBalances[msg.sender][token1];
        if (balance1 > 0) {
            _withdrawBalanceInternalOwner(token1, to, balance1);
        }
    }

    //for owner only
    function _withdrawBalanceInternalOwner(address tokenAddress, address to, uint256 amount) private {
        ownerBalances[msg.sender][tokenAddress] = 0;
        SafeERC20.safeTransfer(IERC20(tokenAddress), to, amount);
    }

    //for caller only
    function _withdrawBalanceInternalCaller(address tokenAddress, address to, uint256 amount) private {
        callerBalances[msg.sender][tokenAddress] = 0;

        uint256 protocolFees = amount.div(protocolReward);
        uint256 callerFees = amount.sub(protocolFees);

        SafeERC20.safeTransfer(IERC20(tokenAddress), to, callerFees);
        SafeERC20.safeTransfer(IERC20(tokenAddress), owner(), protocolFees);
    }

    function _addToken(uint256 tokenId, address account) private {

        require(accountTokens[account].length < MAX_POSITIONS_PER_ADDRESS, "max positions reached");

        // get tokens for this nft
        (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

        _checkApprovals(IERC20(token0), IERC20(token1));

        accountTokens[account].push(tokenId);
        ownerOf[tokenId] = account;
    }

    function _checkApprovals(IERC20 token0, IERC20 token1) private {
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

    function _removeToken(address account, uint256 tokenId) private {
        uint256[] memory accountTokensArr = accountTokens[account];
        uint256 len = accountTokensArr.length;
        uint256 assetIndex = len;

        // limited by MAX_POSITIONS_PER_ADDRESS (no out-of-gas problem)
        for (uint256 i = 0; i < len; i++) {
            if (accountTokensArr[i] == tokenId) {
                assetIndex = i;
                break;
            }
        }

        assert(assetIndex < len);

        uint256[] storage storedList = accountTokens[account];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        delete ownerOf[tokenId];
    }

    // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
    function _swapToPriceRatio(SwapParams memory params) 
        private 
        returns (uint256 amount0, uint256 amount1) 
    {    
        SwapState memory state;

        amount0 = params.amount0;
        amount1 = params.amount1;
        
        // get price
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(params.token0, params.token1, params.fee));
        
        (state.sqrtPriceX96,state.tick,,,,,) = pool.slot0();

        //the risk of an attack on twap price is negligible
        
        //example attack
        //1. attacker swaps a lot of A for B, doing so will decrease the price of A relative to B
        //2. attacker triggers autoCompound for positions in the same uniswap pool as the attack, which increases the liquidity available to them to swap back
        //3. attacker swaps back a greater amount of B for A, benefitting from the reduction in slippage from the liquidity to net a profit
        
        //why it is not an issue:
        // *the amount of fees in the liquidity position, assuming that it is an automated process, will never reach an amount of liquidity that is profitable for the attacker,
        // as it will be compounded efficiently
        // *there is a significant gas cost to compound many positions
        // *a larger pool will not have significant slippage
        // *a smaller pool will not yield significant fees



        // calculate how much of the position needs to be converted to the other token
        if (state.tick >= params.tickUpper) {
            state.delta0 = amount0;
            state.sell0 = true;
        } else if (state.tick <= params.tickLower) {
            state.priceX96 = FullMath.mulDiv(state.sqrtPriceX96, state.sqrtPriceX96, Q96);
            state.delta0 = FullMath.mulDiv(amount1, Q96, state.priceX96);
            state.sell0 = false;
        } else {
            (state.positionAmount0, state.positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                                                            state.sqrtPriceX96, 
                                                            TickMath.getSqrtRatioAtTick(params.tickLower), 
                                                            TickMath.getSqrtRatioAtTick(params.tickUpper), 
                                                            Q96); // dummy value we just need ratio
                                                            
            state.amountRatioX96 = FullMath.mulDiv(state.positionAmount0, Q96, state.positionAmount1);

            uint256 amount1as0 = state.amountRatioX96.mul(amount1);
            uint256 amount0as96 = amount0.mul(Q96);

            uint256 priceX192 = uint256(state.sqrtPriceX96).mul(state.sqrtPriceX96);
            state.sell0 = (amount1as0 < amount0as96);
            if (state.sell0) {
                state.delta0 = amount0as96.sub(amount1as0).div(FullMath.mulDiv(state.amountRatioX96, priceX192, Q192).add(Q96));
            } else {
                state.delta0 = amount1as0.sub(amount0as96).div(FullMath.mulDiv(state.amountRatioX96, priceX192, Q192).add(Q96));
            }
        }
        if (state.delta0 > 0) {
            state.priceX96 = FullMath.mulDiv(state.sqrtPriceX96, state.sqrtPriceX96, Q96);
            if (state.sell0) {
                uint256 amountOut = _swap(
                                        abi.encodePacked(params.token0, params.fee, params.token1), 
                                        state.delta0, 
                                        block.timestamp
                                    );
                amount0 = amount0.sub(state.delta0);
                amount1 = amount1.add(amountOut);
            } else {
                state.delta1 = FullMath.mulDiv(state.delta0, state.priceX96, Q96);
                // prevent possible rounding to 0 issue
                if (state.delta1 > 0) {
                    uint256 amountOut = _swap(
                        abi.encodePacked(params.token1, params.fee, params.token0),
                        state.delta1,
                        block.timestamp
                        );
                    amount0 = amount0.add(amountOut);
                    amount1 = amount1.sub(state.delta1);
                }
            }
        }
    }

    function _swap(bytes memory swapPath, uint256 amount, uint256 deadline) private returns (uint256 amountOut) {
        if (amount > 0) {
            amountOut = swapRouter.exactInput(
                ISwapRouter.ExactInputParams(swapPath, address(this), deadline, amount, 0)
            );
        }
    }
}