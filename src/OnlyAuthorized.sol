// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;

contract OnlyAuthorized {
    address private owner = msg.sender;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
