// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract Test {
    uint public count = 0;
    function start() public returns (uint256) {
        uint gStart = gasleft();
        uint x = 5;
        x += count;

        count = 0;

        uint gEnd = gasleft();
        return gEnd-gStart;
    }
}