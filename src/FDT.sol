// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FDT is ERC20Burnable, Ownable {

    uint256 private constant SUPPLY = 1_000_000_000 * 10**18;

    constructor() ERC20("FIAT DAO Token", "FDT") {
        _mint(msg.sender, SUPPLY);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }
}