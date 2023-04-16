// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "forge-std/Test.sol";
import "../src/Compounder.sol";
import "../src/external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "../src/external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import "../src/ICompounder.sol";

contract CREAT2TEST is Test {
    Compounder public reg;

    INonfungiblePositionManager private nonfungiblePositionManager;
    IUniswapV3Factory private factory;
    ISwapRouter private swapRouter;

    function setUp() public {
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

        reg = new Compounder(factory, nonfungiblePositionManager);
    }

    function getInitHash() public returns (bytes32) {
        bytes memory bytecode = type(Compounder).creationCode;
        console.logBytes(abi.encodePacked(bytecode, abi.encode(factory, nonfungiblePositionManager)));
        return keccak256(abi.encodePacked(bytecode, abi.encode(factory, nonfungiblePositionManager)));
    }

    function testInitHash() public {
        bytes32 initHash = getInitHash();
        emit log_bytes32(initHash);
    }
}