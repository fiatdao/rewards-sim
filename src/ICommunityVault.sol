// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface ICommunityVault {
    function setAllowance(address spender, uint256 amount) external;

    function owner() external view returns (address);
}