// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IMasterChefV3 {
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}