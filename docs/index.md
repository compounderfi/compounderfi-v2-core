# Solidity API

## Compounder

### Important Preface
* `Owner` refers to the owner of the uniswapv3 NFT
* `Caller` refers to the person who calls the AutoCompound function for the owner, will automatically reinvest the fees for that position
* `Position` refers to the uniswap v3 position/NFT
* `Protocol` refers to compounder.fi, the organization who created this contract

### Q96

```solidity
uint128 Q96
```

### Q192

```solidity
uint256 Q192
```

### MAX_POSITIONS_PER_ADDRESS

```solidity
uint32 MAX_POSITIONS_PER_ADDRESS
```

### protocolReward

```solidity
uint64 protocolReward
```

reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### grossCallerReward

```solidity
uint64 grossCallerReward
```

the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees  

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### factory

```solidity
contract IUniswapV3Factory factory
```

### nonfungiblePositionManager

```solidity
contract INonfungiblePositionManager nonfungiblePositionManager
```

### swapRouter

```solidity
contract ISwapRouter swapRouter
```

### ownerOf

```solidity
mapping(uint256 => address) ownerOf
```

returns the owner of a compounder-managed NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### accountTokens

```solidity
mapping(address => uint256[]) accountTokens
```

Tokens of owner by index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### callerBalances

```solidity
mapping(address => mapping(address => uint256)) callerBalances
```

Returns balance of token of callers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor(contract IUniswapV3Factory _factory, contract INonfungiblePositionManager _nonfungiblePositionManager, contract ISwapRouter _swapRouter) public
```

### onlyPositionOwner

```solidity
modifier onlyPositionOwner(uint256 tokenId)
```

modifier that makes sure the owner of a position is the sender

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the tokenId of the position being compared |

### addressToTokens

```solidity
function addressToTokens(address addr) external view returns (uint256[])
```

finds the tokens an address has inside of the protocol

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address of the account |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | uint256[]  an array of the positions he/she has in the protocol |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256 tokenId, bytes) external returns (bytes4)
```

When receiving a Uniswap V3 NFT, deposits token with from as owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
| tokenId | uint256 | the tokenId being deposited into the protocol |
|  | bytes |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | bytes4  openzeppelin: "It must return its Solidity selector to confirm the token transfer" |

### AutoCompound

```solidity
event AutoCompound()
```

### AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d

```solidity
function AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d(uint256 tokenId, bool rewardConversion) external returns (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1)
```

Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)

_AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d saves 70 gas (optimized function selector)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the tokenId being selected to compound |
| rewardConversion | bool | true - take token0 as the caller fee, false - take token1 as the caller fee |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee0 | uint256 | Amount of token0 caller recieves |
| fee1 | uint256 | Amount of token1 caller recieves |
| compounded0 | uint256 | Amount of token0 that was compounded |
| compounded1 | uint256 | Amount of token1 that was compounded |

### decreaseLiquidityAndCollect

```solidity
function decreaseLiquidityAndCollect(struct ICompounder.DecreaseLiquidityAndCollectParams params) external returns (uint256 amount0, uint256 amount1)
```

Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner

_Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ICompounder.DecreaseLiquidityAndCollectParams | DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | amount of token0 removed and collected |
| amount1 | uint256 | amount of token1 removed and collected |

### collect

```solidity
function collect(struct INonfungiblePositionManager.CollectParams params) external returns (uint256 amount0, uint256 amount1)
```

Forwards collect call from NonfungiblePositionManager to nft owner - can only be called by the NFT owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.CollectParams | INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | amount of token0 collected |
| amount1 | uint256 | amount of token1 collected |

### withdrawToken

```solidity
function withdrawToken(uint256 tokenId, address to, bool withdrawBalances, bytes data) external
```

Removes a NFT from the protocol and safe transfers it to address to

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | TokenId of token to remove |
| to | address | Address to send to |
| withdrawBalances | bool | When true sends the available balances for token0 and token1 as well |
| data | bytes | data which is sent with the safeTransferFrom call |

### withdrawBalanceCaller

```solidity
function withdrawBalanceCaller(address tokenAddress, address to) external
```

Withdraws token balance for a caller (their fees for compounding)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of token to withdraw |
| to | address | Address to send to |

### _increaseBalanceCaller

```solidity
function _increaseBalanceCaller(address account, address tokenAddress, uint256 amount) private
```

### _withdrawBalanceInternalCaller

```solidity
function _withdrawBalanceInternalCaller(address tokenAddress, address to, uint256 amount) private
```

### _addToken

```solidity
function _addToken(uint256 tokenId, address account) private
```

### _checkApprovals

```solidity
function _checkApprovals(contract IERC20 token0, contract IERC20 token1) private
```

### _removeToken

```solidity
function _removeToken(address account, uint256 tokenId) private
```

### _swapToPriceRatio

```solidity
function _swapToPriceRatio(struct ICompounder.SwapParams params) private returns (uint256 amount0, uint256 amount1)
```

### _swap

```solidity
function _swap(bytes swapPath, uint256 amount, uint256 deadline) private returns (uint256 amountOut)
```

## ICompounder

### TokenDeposited

```solidity
event TokenDeposited(address account, uint256 tokenId)
```

### TokenWithdrawn

```solidity
event TokenWithdrawn(address account, address to, uint256 tokenId)
```

### protocolReward

```solidity
function protocolReward() external view returns (uint64)
```

reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | the protocolReward |

### grossCallerReward

```solidity
function grossCallerReward() external view returns (uint64)
```

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees |

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address owner)
```

returns the owner of a compounder-managed NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the tokenId being checked |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | the owner of the tokenId |

### accountTokens

```solidity
function accountTokens(address account, uint256 index) external view returns (uint256 tokenId)
```

Tokens of owner by index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | the owner being checked |
| index | uint256 | the index of the array |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the tokenId at that index for that owner |

### callerBalances

```solidity
function callerBalances(address account, address token) external view returns (uint256 balance)
```

Returns balance of token of callers

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Address of account |
| token | address | Address of token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| balance | uint256 | amount debted to the position at token |

### addressToTokens

```solidity
function addressToTokens(address addr) external view returns (uint256[] openPositions)
```

finds the tokens an address has inside of the protocol

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | the address of the account |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| openPositions | uint256[] | an array of the positions he/she has in the protocol |

### withdrawToken

```solidity
function withdrawToken(uint256 tokenId, address to, bool withdrawBalances, bytes data) external
```

Removes a NFT from the protocol and safe transfers it to address to

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | TokenId of token to remove |
| to | address | Address to send to |
| withdrawBalances | bool | When true sends the available balances for token0 and token1 as well |
| data | bytes | data which is sent with the safeTransferFrom call |

### withdrawBalanceCaller

```solidity
function withdrawBalanceCaller(address tokenAddress, address to) external
```

Withdraws token balance for a caller (their fees for compounding)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenAddress | address | Address of token to withdraw |
| to | address | Address to send to |

### AutoCompoundParams

```solidity
struct AutoCompoundParams {
  uint256 tokenId;
  bool rewardConversion;
}
```

### SwapParams

```solidity
struct SwapParams {
  address token0;
  address token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint256 amount0;
  uint256 amount1;
}
```

### AutoCompoundState

```solidity
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
```

### SwapState

```solidity
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
```

### AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d

```solidity
function AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d(uint256 tokenId, bool rewardConversion) external returns (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1)
```

Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)

_AutoCompound30d33f2265e154c31b7c8ba38ce7da3121b5a13d saves 70 gas (optimized function selector)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | the tokenId being selected to compound |
| rewardConversion | bool | true - take token0 as the caller fee, false - take token1 as the caller fee |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee0 | uint256 | Amount of token0 caller recieves |
| fee1 | uint256 | Amount of token1 caller recieves |
| compounded0 | uint256 | Amount of token0 that was compounded |
| compounded1 | uint256 | Amount of token1 that was compounded |

### DecreaseLiquidityAndCollectParams

```solidity
struct DecreaseLiquidityAndCollectParams {
  uint256 tokenId;
  uint128 liquidity;
  uint256 amount0Min;
  uint256 amount1Min;
  uint256 deadline;
  address recipient;
}
```

### decreaseLiquidityAndCollect

```solidity
function decreaseLiquidityAndCollect(struct ICompounder.DecreaseLiquidityAndCollectParams params) external returns (uint256 amount0, uint256 amount1)
```

Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner

_Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ICompounder.DecreaseLiquidityAndCollectParams | DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | amount of token0 removed and collected |
| amount1 | uint256 | amount of token1 removed and collected |

### collect

```solidity
function collect(struct INonfungiblePositionManager.CollectParams params) external returns (uint256 amount0, uint256 amount1)
```

Forwards collect call from NonfungiblePositionManager to nft owner - can only be called by the NFT owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.CollectParams | INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | amount of token0 collected |
| amount1 | uint256 | amount of token1 collected |

## Ownable

_Contract module which provides a basic access control mechanism, where
there is an account (an owner) that can be granted exclusive access to
specific functions.

By default, the owner account will be the one that deploys the contract. This
can later be changed with {transferOwnership}.

This module is used through inheritance. It will make available the modifier
`onlyOwner`, which can be applied to your functions to restrict their use to
the owner._

### _owner

```solidity
address _owner
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### constructor

```solidity
constructor() internal
```

_Initializes the contract setting the deployer as the initial owner._

### owner

```solidity
function owner() public view virtual returns (address)
```

_Returns the address of the current owner._

### onlyOwner

```solidity
modifier onlyOwner()
```

_Throws if called by any account other than the owner._

### renounceOwnership

```solidity
function renounceOwnership() public virtual
```

_Leaves the contract without owner. It will not be possible to call
`onlyOwner` functions anymore. Can only be called by the current owner.

NOTE: Renouncing ownership will leave the contract without an owner,
thereby removing any functionality that is only available to the owner._

### transferOwnership

```solidity
function transferOwnership(address newOwner) public virtual
```

_Transfers ownership of the contract to a new account (`newOwner`).
Can only be called by the current owner._

## IERC165

_Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

## SafeMath

_Wrappers over Solidity's arithmetic operations with added overflow
checks.

Arithmetic operations in Solidity wrap on overflow. This can easily result
in bugs, because programmers usually assume that an overflow raises an
error, which is the standard behavior in high level programming languages.
`SafeMath` restores this intuition by reverting the transaction when an
operation overflows.

Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always._

### tryAdd

```solidity
function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

_Returns the addition of two unsigned integers, with an overflow flag.

_Available since v3.4.__

### trySub

```solidity
function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

_Returns the substraction of two unsigned integers, with an overflow flag.

_Available since v3.4.__

### tryMul

```solidity
function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

_Returns the multiplication of two unsigned integers, with an overflow flag.

_Available since v3.4.__

### tryDiv

```solidity
function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

_Returns the division of two unsigned integers, with a division by zero flag.

_Available since v3.4.__

### tryMod

```solidity
function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

_Returns the remainder of dividing two unsigned integers, with a division by zero flag.

_Available since v3.4.__

### add

```solidity
function add(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the addition of two unsigned integers, reverting on
overflow.

Counterpart to Solidity's `+` operator.

Requirements:

- Addition cannot overflow._

### sub

```solidity
function sub(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the subtraction of two unsigned integers, reverting on
overflow (when the result is negative).

Counterpart to Solidity's `-` operator.

Requirements:

- Subtraction cannot overflow._

### mul

```solidity
function mul(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the multiplication of two unsigned integers, reverting on
overflow.

Counterpart to Solidity's `*` operator.

Requirements:

- Multiplication cannot overflow._

### div

```solidity
function div(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the integer division of two unsigned integers, reverting on
division by zero. The result is rounded towards zero.

Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero._

### mod

```solidity
function mod(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
reverting when dividing by zero.

Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero._

### sub

```solidity
function sub(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

_Returns the subtraction of two unsigned integers, reverting with custom message on
overflow (when the result is negative).

CAUTION: This function is deprecated because it requires allocating memory for the error
message unnecessarily. For custom revert reasons use {trySub}.

Counterpart to Solidity's `-` operator.

Requirements:

- Subtraction cannot overflow._

### div

```solidity
function div(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

_Returns the integer division of two unsigned integers, reverting with custom message on
division by zero. The result is rounded towards zero.

CAUTION: This function is deprecated because it requires allocating memory for the error
message unnecessarily. For custom revert reasons use {tryDiv}.

Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero._

### mod

```solidity
function mod(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

_Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
reverting with custom message when dividing by zero.

CAUTION: This function is deprecated because it requires allocating memory for the error
message unnecessarily. For custom revert reasons use {tryMod}.

Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero._

## IERC20

_Interface of the ERC20 standard as defined in the EIP._

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the amount of tokens in existence._

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the amount of tokens owned by `account`._

### transfer

```solidity
function transfer(address recipient, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from the caller's account to `recipient`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called._

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

_Sets `amount` as the allowance of `spender` over the caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event._

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from `sender` to `recipient` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

_Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).

Note that `value` may be zero._

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

_Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance._

## IERC20Metadata

_Interface for the optional metadata functions from the ERC20 standard.

_Available since v4.1.__

### name

```solidity
function name() external view returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() external view returns (string)
```

_Returns the symbol of the token._

### decimals

```solidity
function decimals() external view returns (uint8)
```

_Returns the decimals places of the token._

## SafeERC20

_Wrappers around ERC20 operations that throw on failure (when the token
contract returns false). Tokens that return no value (and instead revert or
throw on failure) are also supported, non-reverting calls are assumed to be
successful.
To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
which allows you to call the safe operations as `token.safeTransfer(...)`, etc._

### safeTransfer

```solidity
function safeTransfer(contract IERC20 token, address to, uint256 value) internal
```

### safeTransferFrom

```solidity
function safeTransferFrom(contract IERC20 token, address from, address to, uint256 value) internal
```

### safeApprove

```solidity
function safeApprove(contract IERC20 token, address spender, uint256 value) internal
```

_Deprecated. This function has issues similar to the ones found in
{IERC20-approve}, and its usage is discouraged.

Whenever possible, use {safeIncreaseAllowance} and
{safeDecreaseAllowance} instead._

### safeIncreaseAllowance

```solidity
function safeIncreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

### safeDecreaseAllowance

```solidity
function safeDecreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

### _callOptionalReturn

```solidity
function _callOptionalReturn(contract IERC20 token, bytes data) private
```

_Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
on the return value: the return value is optional (but if data is returned, it must not be false)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20 | The token targeted by the call. |
| data | bytes | The call data (encoded using abi.encode or one of its variants). |

## IERC721

_Required interface of an ERC721 compliant contract._

### Transfer

```solidity
event Transfer(address from, address to, uint256 tokenId)
```

_Emitted when `tokenId` token is transferred from `from` to `to`._

### Approval

```solidity
event Approval(address owner, address approved, uint256 tokenId)
```

_Emitted when `owner` enables `approved` to manage the `tokenId` token._

### ApprovalForAll

```solidity
event ApprovalForAll(address owner, address operator, bool approved)
```

_Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets._

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 balance)
```

_Returns the number of tokens in ``owner``'s account._

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address owner)
```

_Returns the owner of the `tokenId` token.

Requirements:

- `tokenId` must exist._

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external
```

_Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event._

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external
```

_Transfers `tokenId` token from `from` to `to`.

WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.

Emits a {Transfer} event._

### approve

```solidity
function approve(address to, uint256 tokenId) external
```

_Gives permission to `to` to transfer `tokenId` token to another account.
The approval is cleared when the token is transferred.

Only a single account can be approved at a time, so approving the zero address clears previous approvals.

Requirements:

- The caller must own the token or be an approved operator.
- `tokenId` must exist.

Emits an {Approval} event._

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address operator)
```

_Returns the account approved for `tokenId` token.

Requirements:

- `tokenId` must exist._

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool _approved) external
```

_Approve or remove `operator` as an operator for the caller.
Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.

Requirements:

- The `operator` cannot be the caller.

Emits an {ApprovalForAll} event._

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool)
```

_Returns if the `operator` is allowed to manage all of the assets of `owner`.

See {setApprovalForAll}_

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external
```

_Safely transfers `tokenId` token from `from` to `to`.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event._

## IERC721Enumerable

_See https://eips.ethereum.org/EIPS/eip-721_

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the total amount of tokens stored by the contract._

### tokenOfOwnerByIndex

```solidity
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId)
```

_Returns a token ID owned by `owner` at a given `index` of its token list.
Use along with {balanceOf} to enumerate all of ``owner``'s tokens._

### tokenByIndex

```solidity
function tokenByIndex(uint256 index) external view returns (uint256)
```

_Returns a token ID at a given `index` of all the tokens stored by the contract.
Use along with {totalSupply} to enumerate all tokens._

## IERC721Metadata

_See https://eips.ethereum.org/EIPS/eip-721_

### name

```solidity
function name() external view returns (string)
```

_Returns the token collection name._

### symbol

```solidity
function symbol() external view returns (string)
```

_Returns the token collection symbol._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) external view returns (string)
```

_Returns the Uniform Resource Identifier (URI) for `tokenId` token._

## IERC721Receiver

_Interface for any contract that wants to support safeTransfers
from ERC721 asset contracts._

### onERC721Received

```solidity
function onERC721Received(address operator, address from, uint256 tokenId, bytes data) external returns (bytes4)
```

_Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
by `operator` from `from`, this function is called.

It must return its Solidity selector to confirm the token transfer.
If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.

The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`._

## Address

_Collection of functions related to the address type_

### isContract

```solidity
function isContract(address account) internal view returns (bool)
```

_Returns true if `account` is a contract.

[IMPORTANT]
====
It is unsafe to assume that an address for which this function returns
false is an externally-owned account (EOA) and not a contract.

Among others, `isContract` will return false for the following
types of addresses:

 - an externally-owned account
 - a contract in construction
 - an address where a contract will be created
 - an address where a contract lived, but was destroyed
====_

### sendValue

```solidity
function sendValue(address payable recipient, uint256 amount) internal
```

_Replacement for Solidity's `transfer`: sends `amount` wei to
`recipient`, forwarding all available gas and reverting on errors.

https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
of certain opcodes, possibly making contracts go over the 2300 gas limit
imposed by `transfer`, making them unable to receive funds via
`transfer`. {sendValue} removes this limitation.

https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].

IMPORTANT: because control is transferred to `recipient`, care must be
taken to not create reentrancy vulnerabilities. Consider using
{ReentrancyGuard} or the
https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern]._

### functionCall

```solidity
function functionCall(address target, bytes data) internal returns (bytes)
```

_Performs a Solidity function call using a low level `call`. A
plain`call` is an unsafe replacement for a function call: use this
function instead.

If `target` reverts with a revert reason, it is bubbled up by this
function (like regular Solidity function calls).

Returns the raw returned data. To convert to the expected return value,
use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

Requirements:

- `target` must be a contract.
- calling `target` with `data` must not revert.

_Available since v3.1.__

### functionCall

```solidity
function functionCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
`errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1.__

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but also transferring `value` wei to `target`.

Requirements:

- the calling contract must have an ETH balance of at least `value`.
- the called Solidity function must be `payable`.

_Available since v3.1.__

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
with `errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1.__

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data) internal view returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a static call.

_Available since v3.3.__

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data, string errorMessage) internal view returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a static call.

_Available since v3.3.__

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a delegate call.

_Available since v3.4.__

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a delegate call.

_Available since v3.4.__

### _verifyCallResult

```solidity
function _verifyCallResult(bool success, bytes returndata, string errorMessage) private pure returns (bytes)
```

## Context

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address payable)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

## Multicall

_Provides a function to batch together multiple calls in a single external call.

_Available since v4.1.__

### multicall

```solidity
function multicall(bytes[] data) external virtual returns (bytes[] results)
```

_Receives and executes a batch of function calls on this contract._

## ReentrancyGuard

_Contract module that helps prevent reentrant calls to a function.

Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
available, which can be applied to functions to make sure there are no nested
(reentrant) calls to them.

Note that because there is a single `nonReentrant` guard, functions marked as
`nonReentrant` may not call one another. This can be worked around by making
those functions `private`, and then adding `external` `nonReentrant` entry
points to them.

TIP: If you would like to learn more about reentrancy and alternative ways
to protect against it, check out our blog post
https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul]._

### _NOT_ENTERED

```solidity
uint256 _NOT_ENTERED
```

### _ENTERED

```solidity
uint256 _ENTERED
```

### _status

```solidity
uint256 _status
```

### constructor

```solidity
constructor() internal
```

### nonReentrant

```solidity
modifier nonReentrant()
```

_Prevents a contract from calling itself, directly or indirectly.
Calling a `nonReentrant` function from another `nonReentrant`
function is not supported. It is possible to prevent this from happening
by making the `nonReentrant` function external, and make it call a
`private` function that does the actual work._

## IUniswapV3Factory

The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees

### OwnerChanged

```solidity
event OwnerChanged(address oldOwner, address newOwner)
```

Emitted when the owner of the factory is changed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldOwner | address | The owner before the owner was changed |
| newOwner | address | The owner after the owner was changed |

### PoolCreated

```solidity
event PoolCreated(address token0, address token1, uint24 fee, int24 tickSpacing, address pool)
```

Emitted when a pool is created

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The first token of the pool by address sort order |
| token1 | address | The second token of the pool by address sort order |
| fee | uint24 | The fee collected upon every swap in the pool, denominated in hundredths of a bip |
| tickSpacing | int24 | The minimum number of ticks between initialized ticks |
| pool | address | The address of the created pool |

### FeeAmountEnabled

```solidity
event FeeAmountEnabled(uint24 fee, int24 tickSpacing)
```

Emitted when a new fee amount is enabled for pool creation via the factory

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint24 | The enabled fee, denominated in hundredths of a bip |
| tickSpacing | int24 | The minimum number of ticks between initialized ticks for pools created with the given fee |

### owner

```solidity
function owner() external view returns (address)
```

Returns the current owner of the factory

_Can be changed by the current owner via setOwner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the factory owner |

### feeAmountTickSpacing

```solidity
function feeAmountTickSpacing(uint24 fee) external view returns (int24)
```

Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled

_A fee amount can never be removed, so this value should be hard coded or cached in the calling context_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint24 | The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | int24 | The tick spacing |

### getPool

```solidity
function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)
```

Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist

_tokenA and tokenB may be passed in either token0/token1 or token1/token0 order_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenA | address | The contract address of either token0 or token1 |
| tokenB | address | The contract address of the other token |
| fee | uint24 | The fee collected upon every swap in the pool, denominated in hundredths of a bip |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The pool address |

### createPool

```solidity
function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool)
```

Creates a pool for the given two tokens and fee

_tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
are invalid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenA | address | One of the two tokens in the desired pool |
| tokenB | address | The other of the two tokens in the desired pool |
| fee | uint24 | The desired fee for the pool |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the newly created pool |

### setOwner

```solidity
function setOwner(address _owner) external
```

Updates the owner of the factory

_Must be called by the current owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _owner | address | The new owner of the factory |

### enableFeeAmount

```solidity
function enableFeeAmount(uint24 fee, int24 tickSpacing) external
```

Enables a fee amount with the given tickSpacing

_Fee amounts may never be removed once enabled_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint24 | The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6) |
| tickSpacing | int24 | The spacing between ticks to be enforced for all pools created with the given fee amount |

## IUniswapV3Pool

A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
to the ERC20 specification

_The pool interface is broken up into many smaller pieces_

## IUniswapV3SwapCallback

Any contract that calls IUniswapV3PoolActions#swap must implement this interface

### uniswapV3SwapCallback

```solidity
function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes data) external
```

Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.

_In the implementation you must pay the pool tokens owed for the swap.
The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
amount0Delta and amount1Delta can both be 0 if no tokens were swapped._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Delta | int256 | The amount of token0 that was sent (negative) or must be received (positive) by the pool by the end of the swap. If positive, the callback must send that amount of token0 to the pool. |
| amount1Delta | int256 | The amount of token1 that was sent (negative) or must be received (positive) by the pool by the end of the swap. If positive, the callback must send that amount of token1 to the pool. |
| data | bytes | Any data passed through by the caller via the IUniswapV3PoolActions#swap call |

## IUniswapV3PoolActions

Contains pool methods that can be called by anyone

### initialize

```solidity
function initialize(uint160 sqrtPriceX96) external
```

Sets the initial price for the pool

_Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtPriceX96 | uint160 | the initial sqrt price of the pool as a Q64.96 |

### mint

```solidity
function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes data) external returns (uint256 amount0, uint256 amount1)
```

Adds liquidity for the given recipient/tickLower/tickUpper position

_The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
on tickLower, tickUpper, the amount of liquidity, and the current price._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address for which the liquidity will be created |
| tickLower | int24 | The lower tick of the position in which to add liquidity |
| tickUpper | int24 | The upper tick of the position in which to add liquidity |
| amount | uint128 | The amount of liquidity to mint |
| data | bytes | Any data that should be passed through to the callback |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback |
| amount1 | uint256 | The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback |

### collect

```solidity
function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1)
```

Collects tokens owed to a position

_Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address which should receive the fees collected |
| tickLower | int24 | The lower tick of the position for which to collect fees |
| tickUpper | int24 | The upper tick of the position for which to collect fees |
| amount0Requested | uint128 | How much token0 should be withdrawn from the fees owed |
| amount1Requested | uint128 | How much token1 should be withdrawn from the fees owed |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint128 | The amount of fees collected in token0 |
| amount1 | uint128 | The amount of fees collected in token1 |

### burn

```solidity
function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1)
```

Burn liquidity from the sender and account tokens owed for the liquidity to the position

_Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
Fees must be collected separately via a call to #collect_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick of the position for which to burn liquidity |
| tickUpper | int24 | The upper tick of the position for which to burn liquidity |
| amount | uint128 | How much liquidity to burn |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 sent to the recipient |
| amount1 | uint256 | The amount of token1 sent to the recipient |

### swap

```solidity
function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes data) external returns (int256 amount0, int256 amount1)
```

Swap token0 for token1, or token1 for token0

_The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address to receive the output of the swap |
| zeroForOne | bool | The direction of the swap, true for token0 to token1, false for token1 to token0 |
| amountSpecified | int256 | The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative) |
| sqrtPriceLimitX96 | uint160 | The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap |
| data | bytes | Any data to be passed through to the callback |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | int256 | The delta of the balance of token0 of the pool, exact when negative, minimum when positive |
| amount1 | int256 | The delta of the balance of token1 of the pool, exact when negative, minimum when positive |

### flash

```solidity
function flash(address recipient, uint256 amount0, uint256 amount1, bytes data) external
```

Receive token0 and/or token1 and pay it back, plus a fee, in the callback

_The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
with 0 amount{0,1} and sending the donation amount(s) from the callback_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address which will receive the token0 and token1 amounts |
| amount0 | uint256 | The amount of token0 to send |
| amount1 | uint256 | The amount of token1 to send |
| data | bytes | Any data to be passed through to the callback |

### increaseObservationCardinalityNext

```solidity
function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external
```

Increase the maximum number of price and liquidity observations that this pool will store

_This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
the input observationCardinalityNext._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| observationCardinalityNext | uint16 | The desired minimum number of observations for the pool to store |

## IUniswapV3PoolDerivedState

Contains view functions to provide information about the pool that is computed rather than stored on the
blockchain. The functions here may have variable gas costs.

### observe

```solidity
function observe(uint32[] secondsAgos) external view returns (int56[] tickCumulatives, uint160[] secondsPerLiquidityCumulativeX128s)
```

Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp

_To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
you must call it with secondsAgos = [3600, 0].
The time weighted average tick represents the geometric time weighted average price of the pool, in
log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| secondsAgos | uint32[] | From how long ago each cumulative tick and liquidity value should be returned |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickCumulatives | int56[] | Cumulative tick values as of each `secondsAgos` from the current block timestamp |
| secondsPerLiquidityCumulativeX128s | uint160[] | Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp |

### snapshotCumulativesInside

```solidity
function snapshotCumulativesInside(int24 tickLower, int24 tickUpper) external view returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside)
```

Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range

_Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
snapshot is taken and the second snapshot is taken._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick of the range |
| tickUpper | int24 | The upper tick of the range |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickCumulativeInside | int56 | The snapshot of the tick accumulator for the range |
| secondsPerLiquidityInsideX128 | uint160 | The snapshot of seconds per liquidity for the range |
| secondsInside | uint32 | The snapshot of seconds per liquidity for the range |

## IUniswapV3PoolEvents

Contains all events emitted by the pool

### Initialize

```solidity
event Initialize(uint160 sqrtPriceX96, int24 tick)
```

Emitted exactly once by a pool when #initialize is first called on the pool

_Mint/Burn/Swap cannot be emitted by the pool before Initialize_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtPriceX96 | uint160 | The initial sqrt price of the pool, as a Q64.96 |
| tick | int24 | The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool |

### Mint

```solidity
event Mint(address sender, address owner, int24 tickLower, int24 tickUpper, uint128 amount, uint256 amount0, uint256 amount1)
```

Emitted when liquidity is minted for a given position

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address that minted the liquidity |
| owner | address | The owner of the position and recipient of any minted liquidity |
| tickLower | int24 | The lower tick of the position |
| tickUpper | int24 | The upper tick of the position |
| amount | uint128 | The amount of liquidity minted to the position range |
| amount0 | uint256 | How much token0 was required for the minted liquidity |
| amount1 | uint256 | How much token1 was required for the minted liquidity |

### Collect

```solidity
event Collect(address owner, address recipient, int24 tickLower, int24 tickUpper, uint128 amount0, uint128 amount1)
```

Emitted when fees are collected by the owner of a position

_Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner of the position for which fees are collected |
| recipient | address |  |
| tickLower | int24 | The lower tick of the position |
| tickUpper | int24 | The upper tick of the position |
| amount0 | uint128 | The amount of token0 fees collected |
| amount1 | uint128 | The amount of token1 fees collected |

### Burn

```solidity
event Burn(address owner, int24 tickLower, int24 tickUpper, uint128 amount, uint256 amount0, uint256 amount1)
```

Emitted when a position's liquidity is removed

_Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The owner of the position for which liquidity is removed |
| tickLower | int24 | The lower tick of the position |
| tickUpper | int24 | The upper tick of the position |
| amount | uint128 | The amount of liquidity to remove |
| amount0 | uint256 | The amount of token0 withdrawn |
| amount1 | uint256 | The amount of token1 withdrawn |

### Swap

```solidity
event Swap(address sender, address recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick)
```

Emitted by the pool for any swaps between token0 and token1

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address that initiated the swap call, and that received the callback |
| recipient | address | The address that received the output of the swap |
| amount0 | int256 | The delta of the token0 balance of the pool |
| amount1 | int256 | The delta of the token1 balance of the pool |
| sqrtPriceX96 | uint160 | The sqrt(price) of the pool after the swap, as a Q64.96 |
| liquidity | uint128 | The liquidity of the pool after the swap |
| tick | int24 | The log base 1.0001 of price of the pool after the swap |

### Flash

```solidity
event Flash(address sender, address recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1)
```

Emitted by the pool for any flashes of token0/token1

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address that initiated the swap call, and that received the callback |
| recipient | address | The address that received the tokens from flash |
| amount0 | uint256 | The amount of token0 that was flashed |
| amount1 | uint256 | The amount of token1 that was flashed |
| paid0 | uint256 | The amount of token0 paid for the flash, which can exceed the amount0 plus the fee |
| paid1 | uint256 | The amount of token1 paid for the flash, which can exceed the amount1 plus the fee |

### IncreaseObservationCardinalityNext

```solidity
event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew)
```

Emitted by the pool for increases to the number of observations that can be stored

_observationCardinalityNext is not the observation cardinality until an observation is written at the index
just before a mint/swap/burn._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| observationCardinalityNextOld | uint16 | The previous value of the next observation cardinality |
| observationCardinalityNextNew | uint16 | The updated value of the next observation cardinality |

### SetFeeProtocol

```solidity
event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New)
```

Emitted when the protocol fee is changed by the pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| feeProtocol0Old | uint8 | The previous value of the token0 protocol fee |
| feeProtocol1Old | uint8 | The previous value of the token1 protocol fee |
| feeProtocol0New | uint8 | The updated value of the token0 protocol fee |
| feeProtocol1New | uint8 | The updated value of the token1 protocol fee |

### CollectProtocol

```solidity
event CollectProtocol(address sender, address recipient, uint128 amount0, uint128 amount1)
```

Emitted when the collected protocol fees are withdrawn by the factory owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The address that collects the protocol fees |
| recipient | address | The address that receives the collected protocol fees |
| amount0 | uint128 | The amount of token0 protocol fees that is withdrawn |
| amount1 | uint128 |  |

## IUniswapV3PoolImmutables

These parameters are fixed for a pool forever, i.e., the methods will always return the same values

### factory

```solidity
function factory() external view returns (address)
```

The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The contract address |

### token0

```solidity
function token0() external view returns (address)
```

The first of the two tokens of the pool, sorted by address

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The token contract address |

### token1

```solidity
function token1() external view returns (address)
```

The second of the two tokens of the pool, sorted by address

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The token contract address |

### fee

```solidity
function fee() external view returns (uint24)
```

The pool's fee in hundredths of a bip, i.e. 1e-6

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint24 | The fee |

### tickSpacing

```solidity
function tickSpacing() external view returns (int24)
```

The pool tick spacing

_Ticks can only be used at multiples of this value, minimum of 1 and always positive
e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
This value is an int24 to avoid casting even though it is always positive._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | int24 | The tick spacing |

### maxLiquidityPerTick

```solidity
function maxLiquidityPerTick() external view returns (uint128)
```

The maximum amount of position liquidity that can use any tick in the range

_This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint128 | The max amount of liquidity per tick |

## IUniswapV3PoolOwnerActions

Contains pool methods that may only be called by the factory owner

### setFeeProtocol

```solidity
function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external
```

Set the denominator of the protocol's % share of the fees

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| feeProtocol0 | uint8 | new protocol fee for token0 of the pool |
| feeProtocol1 | uint8 | new protocol fee for token1 of the pool |

### collectProtocol

```solidity
function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1)
```

Collect the protocol fee accrued to the pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address to which collected protocol fees should be sent |
| amount0Requested | uint128 | The maximum amount of token0 to send, can be 0 to collect fees in only token1 |
| amount1Requested | uint128 | The maximum amount of token1 to send, can be 0 to collect fees in only token0 |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint128 | The protocol fee collected in token0 |
| amount1 | uint128 | The protocol fee collected in token1 |

## IUniswapV3PoolState

These methods compose the pool's state, and can change with any frequency including multiple times
per transaction

### slot0

```solidity
function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)
```

The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
when accessed externally.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtPriceX96 | uint160 | The current price of the pool as a sqrt(token1/token0) Q64.96 value tick The current tick of the pool, i.e. according to the last tick transition that was run. This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick boundary. observationIndex The index of the last oracle observation that was written, observationCardinality The current maximum number of observations stored in the pool, observationCardinalityNext The next maximum number of observations, to be updated when the observation. feeProtocol The protocol fee for both tokens of the pool. Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0 is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee. unlocked Whether the pool is currently locked to reentrancy |
| tick | int24 |  |
| observationIndex | uint16 |  |
| observationCardinality | uint16 |  |
| observationCardinalityNext | uint16 |  |
| feeProtocol | uint8 |  |
| unlocked | bool |  |

### feeGrowthGlobal0X128

```solidity
function feeGrowthGlobal0X128() external view returns (uint256)
```

The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool

_This value can overflow the uint256_

### feeGrowthGlobal1X128

```solidity
function feeGrowthGlobal1X128() external view returns (uint256)
```

The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool

_This value can overflow the uint256_

### protocolFees

```solidity
function protocolFees() external view returns (uint128 token0, uint128 token1)
```

The amounts of token0 and token1 that are owed to the protocol

_Protocol fees will never exceed uint128 max in either token_

### liquidity

```solidity
function liquidity() external view returns (uint128)
```

The currently in range liquidity available to the pool

_This value has no relationship to the total liquidity across all ticks_

### ticks

```solidity
function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized)
```

Look up information about a specific tick in the pool

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tick | int24 | The tick to look up |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidityGross | uint128 | the total amount of position liquidity that uses the pool either as tick lower or tick upper, liquidityNet how much liquidity changes when the pool price crosses the tick, feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0, feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1, tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick, secondsOutside the seconds spent on the other side of the tick from the current tick, initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false. Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0. In addition, these values are only relative and must be used only in comparison to previous snapshots for a specific position. |
| liquidityNet | int128 |  |
| feeGrowthOutside0X128 | uint256 |  |
| feeGrowthOutside1X128 | uint256 |  |
| tickCumulativeOutside | int56 |  |
| secondsPerLiquidityOutsideX128 | uint160 |  |
| secondsOutside | uint32 |  |
| initialized | bool |  |

### tickBitmap

```solidity
function tickBitmap(int16 wordPosition) external view returns (uint256)
```

Returns 256 packed tick initialized boolean values. See TickBitmap for more information

### positions

```solidity
function positions(bytes32 key) external view returns (uint128 _liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)
```

Returns the information about a position by the position's key

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| key | bytes32 | The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| _liquidity | uint128 | The amount of liquidity in the position, Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke, Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke, Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke, Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke |
| feeGrowthInside0LastX128 | uint256 |  |
| feeGrowthInside1LastX128 | uint256 |  |
| tokensOwed0 | uint128 |  |
| tokensOwed1 | uint128 |  |

### observations

```solidity
function observations(uint256 index) external view returns (uint32 blockTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, bool initialized)
```

Returns data about a specific observation index

_You most likely want to use #observe() instead of this method to get an observation as of some amount of time
ago, rather than at a specific index in the array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The element of the observations array to fetch |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| blockTimestamp | uint32 | The timestamp of the observation, Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp, Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp, Returns initialized whether the observation has been initialized and the values are safe to use |
| tickCumulative | int56 |  |
| secondsPerLiquidityCumulativeX128 | uint160 |  |
| initialized | bool |  |

## FixedPoint96

A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)

_Used in SqrtPriceMath.sol_

### RESOLUTION

```solidity
uint8 RESOLUTION
```

### Q96

```solidity
uint256 Q96
```

## FullMath

Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision

_Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits_

### mulDiv

```solidity
function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result)
```

Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0

_Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| a | uint256 | The multiplicand |
| b | uint256 | The multiplier |
| denominator | uint256 | The divisor |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| result | uint256 | The 256-bit result |

### mulDivRoundingUp

```solidity
function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result)
```

Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| a | uint256 | The multiplicand |
| b | uint256 | The multiplier |
| denominator | uint256 | The divisor |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| result | uint256 | The 256-bit result |

## TickMath

Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
prices between 2**-128 and 2**128

### MIN_TICK

```solidity
int24 MIN_TICK
```

_The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128_

### MAX_TICK

```solidity
int24 MAX_TICK
```

_The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128_

### MIN_SQRT_RATIO

```solidity
uint160 MIN_SQRT_RATIO
```

_The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)_

### MAX_SQRT_RATIO

```solidity
uint160 MAX_SQRT_RATIO
```

_The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)_

### getSqrtRatioAtTick

```solidity
function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96)
```

Calculates sqrt(1.0001^tick) * 2^96

_Throws if |tick| > max tick_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tick | int24 | The input tick for the above formula |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtPriceX96 | uint160 | A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0) at the given tick |

### getTickAtSqrtRatio

```solidity
function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick)
```

Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio

_Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
ever return._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtPriceX96 | uint160 | The sqrt ratio for which to compute the tick as a Q64.96 |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tick | int24 | The greatest tick for which the ratio is less than or equal to the input ratio |

## IERC721Permit

Extension to ERC721 that includes a permit function for signature based approvals

### PERMIT_TYPEHASH

```solidity
function PERMIT_TYPEHASH() external pure returns (bytes32)
```

The permit typehash used in the permit signature

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The typehash for the permit |

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

The domain separator used in the permit signature

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The domain seperator used in encoding of permit signature |

### permit

```solidity
function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable
```

Approve of a specific token ID for spending by spender via signature

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | The account that is being approved |
| tokenId | uint256 | The ID of the token that is being approved for spending |
| deadline | uint256 | The deadline timestamp by which the call must be mined for the approve to work |
| v | uint8 | Must produce valid secp256k1 signature from the holder along with `r` and `s` |
| r | bytes32 | Must produce valid secp256k1 signature from the holder along with `v` and `s` |
| s | bytes32 | Must produce valid secp256k1 signature from the holder along with `r` and `v` |

## INonfungiblePositionManager

Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
and authorized.

### IncreaseLiquidity

```solidity
event IncreaseLiquidity(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Emitted when liquidity is increased for a position NFT

_Also emitted when a token is minted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token for which liquidity was increased |
| liquidity | uint128 | The amount by which liquidity for the NFT position was increased |
| amount0 | uint256 | The amount of token0 that was paid for the increase in liquidity |
| amount1 | uint256 | The amount of token1 that was paid for the increase in liquidity |

### DecreaseLiquidity

```solidity
event DecreaseLiquidity(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Emitted when liquidity is decreased for a position NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token for which liquidity was decreased |
| liquidity | uint128 | The amount by which liquidity for the NFT position was decreased |
| amount0 | uint256 | The amount of token0 that was accounted for the decrease in liquidity |
| amount1 | uint256 | The amount of token1 that was accounted for the decrease in liquidity |

### Collect

```solidity
event Collect(uint256 tokenId, address recipient, uint256 amount0, uint256 amount1)
```

Emitted when tokens are collected for a position NFT

_The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token for which underlying tokens were collected |
| recipient | address | The address of the account that received the collected tokens |
| amount0 | uint256 | The amount of token0 owed to the position that was collected |
| amount1 | uint256 | The amount of token1 owed to the position that was collected |

### positions

```solidity
function positions(uint256 tokenId) external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)
```

Returns the position information associated with a given token ID.

_Throws if the token ID is not valid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the position |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| nonce | uint96 | The nonce for permits |
| operator | address | The address that is approved for spending |
| token0 | address | The address of the token0 for a specific pool |
| token1 | address | The address of the token1 for a specific pool |
| fee | uint24 | The fee associated with the pool |
| tickLower | int24 | The lower end of the tick range for the position |
| tickUpper | int24 | The higher end of the tick range for the position |
| liquidity | uint128 | The liquidity of the position |
| feeGrowthInside0LastX128 | uint256 | The fee growth of token0 as of the last action on the individual position |
| feeGrowthInside1LastX128 | uint256 | The fee growth of token1 as of the last action on the individual position |
| tokensOwed0 | uint128 | The uncollected amount of token0 owed to the position as of the last computation |
| tokensOwed1 | uint128 | The uncollected amount of token1 owed to the position as of the last computation |

### MintParams

```solidity
struct MintParams {
  address token0;
  address token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 amount0Min;
  uint256 amount1Min;
  address recipient;
  uint256 deadline;
}
```

### mint

```solidity
function mint(struct INonfungiblePositionManager.MintParams params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Creates a new position wrapped in a NFT

_Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
a method does not exist, i.e. the pool is assumed to be initialized._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.MintParams | The params necessary to mint a position, encoded as `MintParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the minted position |
| liquidity | uint128 | The amount of liquidity for this position |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

### IncreaseLiquidityParams

```solidity
struct IncreaseLiquidityParams {
  uint256 tokenId;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 amount0Min;
  uint256 amount1Min;
  uint256 deadline;
}
```

### increaseLiquidity

```solidity
function increaseLiquidity(struct INonfungiblePositionManager.IncreaseLiquidityParams params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1)
```

Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.IncreaseLiquidityParams | tokenId The ID of the token for which liquidity is being increased, amount0Desired The desired amount of token0 to be spent, amount1Desired The desired amount of token1 to be spent, amount0Min The minimum amount of token0 to spend, which serves as a slippage check, amount1Min The minimum amount of token1 to spend, which serves as a slippage check, deadline The time by which the transaction must be included to effect the change |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The new liquidity amount as a result of the increase |
| amount0 | uint256 | The amount of token0 to acheive resulting liquidity |
| amount1 | uint256 | The amount of token1 to acheive resulting liquidity |

### DecreaseLiquidityParams

```solidity
struct DecreaseLiquidityParams {
  uint256 tokenId;
  uint128 liquidity;
  uint256 amount0Min;
  uint256 amount1Min;
  uint256 deadline;
}
```

### decreaseLiquidity

```solidity
function decreaseLiquidity(struct INonfungiblePositionManager.DecreaseLiquidityParams params) external payable returns (uint256 amount0, uint256 amount1)
```

Decreases the amount of liquidity in a position and accounts it to the position

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.DecreaseLiquidityParams | tokenId The ID of the token for which liquidity is being decreased, amount The amount by which liquidity will be decreased, amount0Min The minimum amount of token0 that should be accounted for the burned liquidity, amount1Min The minimum amount of token1 that should be accounted for the burned liquidity, deadline The time by which the transaction must be included to effect the change |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 accounted to the position's tokens owed |
| amount1 | uint256 | The amount of token1 accounted to the position's tokens owed |

### CollectParams

```solidity
struct CollectParams {
  uint256 tokenId;
  address recipient;
  uint128 amount0Max;
  uint128 amount1Max;
}
```

### collect

```solidity
function collect(struct INonfungiblePositionManager.CollectParams params) external payable returns (uint256 amount0, uint256 amount1)
```

Collects up to a maximum amount of fees owed to a specific position to the recipient

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.CollectParams | tokenId The ID of the NFT for which tokens are being collected, recipient The account that should receive the tokens, amount0Max The maximum amount of token0 to collect, amount1Max The maximum amount of token1 to collect |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of fees collected in token0 |
| amount1 | uint256 | The amount of fees collected in token1 |

### burn

```solidity
function burn(uint256 tokenId) external payable
```

Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
must be collected first.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that is being burned |

## IPeripheryImmutableState

Functions that return immutable state of the router

### factory

```solidity
function factory() external view returns (address)
```

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Returns the address of the Uniswap V3 factory |

### WETH9

```solidity
function WETH9() external view returns (address)
```

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Returns the address of WETH9 |

## IPeripheryPayments

Functions to ease deposits and withdrawals of ETH

### unwrapWETH9

```solidity
function unwrapWETH9(uint256 amountMinimum, address recipient) external payable
```

Unwraps the contract's WETH9 balance and sends it to recipient as ETH.

_The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountMinimum | uint256 | The minimum amount of WETH9 to unwrap |
| recipient | address | The address receiving ETH |

### refundETH

```solidity
function refundETH() external payable
```

Refunds any ETH balance held by this contract to the `msg.sender`

_Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
that use ether for the input amount_

### sweepToken

```solidity
function sweepToken(address token, uint256 amountMinimum, address recipient) external payable
```

Transfers the full amount of a token held by this contract to recipient

_The amountMinimum parameter prevents malicious contracts from stealing the token from users_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The contract address of the token which will be transferred to `recipient` |
| amountMinimum | uint256 | The minimum amount of token required for a transfer |
| recipient | address | The destination address of the token |

## IPoolInitializer

Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
require the pool to exist.

### createAndInitializePoolIfNecessary

```solidity
function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external payable returns (address pool)
```

Creates a new pool if it does not exist, then initializes if not initialized

_This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The contract address of token0 of the pool |
| token1 | address | The contract address of token1 of the pool |
| fee | uint24 | The fee amount of the v3 pool for the specified token pair |
| sqrtPriceX96 | uint160 | The initial square root price of the pool as a Q64.96 value |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary |

## ISwapRouter

Functions for swapping tokens via Uniswap V3

### ExactInputSingleParams

```solidity
struct ExactInputSingleParams {
  address tokenIn;
  address tokenOut;
  uint24 fee;
  address recipient;
  uint256 deadline;
  uint256 amountIn;
  uint256 amountOutMinimum;
  uint160 sqrtPriceLimitX96;
}
```

### exactInputSingle

```solidity
function exactInputSingle(struct ISwapRouter.ExactInputSingleParams params) external payable returns (uint256 amountOut)
```

Swaps `amountIn` of one token for as much as possible of another token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ISwapRouter.ExactInputSingleParams | The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountOut | uint256 | The amount of the received token |

### ExactInputParams

```solidity
struct ExactInputParams {
  bytes path;
  address recipient;
  uint256 deadline;
  uint256 amountIn;
  uint256 amountOutMinimum;
}
```

### exactInput

```solidity
function exactInput(struct ISwapRouter.ExactInputParams params) external payable returns (uint256 amountOut)
```

Swaps `amountIn` of one token for as much as possible of another along the specified path

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ISwapRouter.ExactInputParams | The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountOut | uint256 | The amount of the received token |

### ExactOutputSingleParams

```solidity
struct ExactOutputSingleParams {
  address tokenIn;
  address tokenOut;
  uint24 fee;
  address recipient;
  uint256 deadline;
  uint256 amountOut;
  uint256 amountInMaximum;
  uint160 sqrtPriceLimitX96;
}
```

### exactOutputSingle

```solidity
function exactOutputSingle(struct ISwapRouter.ExactOutputSingleParams params) external payable returns (uint256 amountIn)
```

Swaps as little as possible of one token for `amountOut` of another token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ISwapRouter.ExactOutputSingleParams | The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountIn | uint256 | The amount of the input token |

### ExactOutputParams

```solidity
struct ExactOutputParams {
  bytes path;
  address recipient;
  uint256 deadline;
  uint256 amountOut;
  uint256 amountInMaximum;
}
```

### exactOutput

```solidity
function exactOutput(struct ISwapRouter.ExactOutputParams params) external payable returns (uint256 amountIn)
```

Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct ISwapRouter.ExactOutputParams | The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountIn | uint256 | The amount of the input token |

## LiquidityAmounts

Provides functions for computing liquidity amounts from token amounts and prices

### toUint128

```solidity
function toUint128(uint256 x) internal pure returns (uint128 y)
```

Downcasts uint256 to uint128

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| x | uint256 | The uint258 to be downcasted |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| y | uint128 | The passed value, downcasted to uint128 |

### getLiquidityForAmount0

```solidity
function getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0) internal pure returns (uint128 liquidity)
```

Computes the amount of liquidity received for a given amount of token0 and price range

_Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| amount0 | uint256 | The amount0 being sent in |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The amount of returned liquidity |

### getLiquidityForAmount1

```solidity
function getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount1) internal pure returns (uint128 liquidity)
```

Computes the amount of liquidity received for a given amount of token1 and price range

_Calculates amount1 / (sqrt(upper) - sqrt(lower))._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| amount1 | uint256 | The amount1 being sent in |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The amount of returned liquidity |

### getLiquidityForAmounts

```solidity
function getLiquidityForAmounts(uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0, uint256 amount1) internal pure returns (uint128 liquidity)
```

Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
pool prices and the prices at the tick boundaries

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioX96 | uint160 | A sqrt price representing the current pool prices |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| amount0 | uint256 | The amount of token0 being sent in |
| amount1 | uint256 | The amount of token1 being sent in |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The maximum amount of liquidity received |

### getAmount0ForLiquidity

```solidity
function getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint256 amount0)
```

Computes the amount of token0 for a given amount of liquidity and a price range

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| liquidity | uint128 | The liquidity being valued |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 |

### getAmount1ForLiquidity

```solidity
function getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint256 amount1)
```

Computes the amount of token1 for a given amount of liquidity and a price range

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| liquidity | uint128 | The liquidity being valued |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount1 | uint256 | The amount of token1 |

### getAmountsForLiquidity

```solidity
function getAmountsForLiquidity(uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint256 amount0, uint256 amount1)
```

Computes the token0 and token1 value for a given amount of liquidity, the current
pool prices and the prices at the tick boundaries

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sqrtRatioX96 | uint160 | A sqrt price representing the current pool prices |
| sqrtRatioAX96 | uint160 | A sqrt price representing the first tick boundary |
| sqrtRatioBX96 | uint160 | A sqrt price representing the second tick boundary |
| liquidity | uint128 | The liquidity being valued |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

## PoolAddress

### POOL_INIT_CODE_HASH

```solidity
bytes32 POOL_INIT_CODE_HASH
```

### PoolKey

```solidity
struct PoolKey {
  address token0;
  address token1;
  uint24 fee;
}
```

### getPoolKey

```solidity
function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (struct PoolAddress.PoolKey)
```

Returns PoolKey: the ordered tokens with the matched fee levels

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenA | address | The first token of a pool, unsorted |
| tokenB | address | The second token of a pool, unsorted |
| fee | uint24 | The fee level of the pool |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct PoolAddress.PoolKey | Poolkey The pool details with ordered token0 and token1 assignments |

### computeAddress

```solidity
function computeAddress(address factory, struct PoolAddress.PoolKey key) internal pure returns (address pool)
```

Deterministically computes the pool address given the factory and PoolKey

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| factory | address | The Uniswap V3 factory contract address |
| key | struct PoolAddress.PoolKey | The PoolKey |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The contract address of the V3 pool |

## IERC20Minimal

Contains a subset of the full ERC20 interface that is used in Uniswap V3

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

Returns the balance of a token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account for which to look up the number of tokens it has, i.e. its balance |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of tokens held by the account |

### transfer

```solidity
function transfer(address recipient, uint256 amount) external returns (bool)
```

Transfers the amount of token from the `msg.sender` to the recipient

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The account that will receive the amount transferred |
| amount | uint256 | The number of tokens to send from the sender to the recipient |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful transfer, false for an unsuccessful transfer |

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

Returns the current allowance given to a spender by an owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The account of the token owner |
| spender | address | The account of the token spender |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current allowance granted by `owner` to `spender` |

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

Sets the allowance of a spender from the `msg.sender` to the value `amount`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | The account which will be allowed to spend a given amount of the owners tokens |
| amount | uint256 | The amount of tokens allowed to be used by `spender` |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful approval, false for unsuccessful |

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
```

Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The account from which the transfer will be initiated |
| recipient | address | The recipient of the transfer |
| amount | uint256 | The amount of the transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful transfer, false for unsuccessful |

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The account from which the tokens were sent, i.e. the balance decreased |
| to | address | The account to which the tokens were sent, i.e. the balance increased |
| value | uint256 | The amount of tokens that were transferred |

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

Event emitted when the approval amount for the spender of a given owner's tokens changes.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The account that approved spending of its tokens |
| spender | address | The account for which the spending allowance was modified |
| value | uint256 | The new allowance from the owner to the spender |

