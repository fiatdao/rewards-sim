// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "ds-test/test.sol";
import {Hevm} from "./test/utils/Hevm.sol";

import {Rewards} from "lib/comitium/contracts/Rewards.sol";
import {Comitium} from "lib/comitium/contracts/Comitium.sol";
import {ComitiumFacet} from "lib/comitium/contracts/facets/ComitiumFacet.sol";

import {FDT} from "./FDT.sol";

contract RewardsTest is DSTest {
    // Cheat codes
    Hevm internal hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // Rewards
    Rewards private rewards =
        Rewards(0x2458Fd408F5D2c61a4819E9d6DB43A81011E42a7);

    // Comitium
    Comitium private comitium =
        Comitium(0x4645d1cF3f4cE59b06008642E74E60e8F80c8b58);
    bytes32 private DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");
    bytes32 private COMITIUM_STORAGE_POSITION =
        keccak256("com.fiatdao.comitium.storage");
    ComitiumFacet private comitiumFacet = ComitiumFacet(address(comitium));

    // FIAT DAO Token
    FDT private fdt = FDT(0xEd1480d12bE41d92F36f5f7bDd88212E381A3677);

    function owner() internal returns (address) {
        return
            address(
                uint160(
                    uint256(
                        hevm.load(
                            address(comitium),
                            bytes32(uint256(DIAMOND_STORAGE_POSITION) + 3)
                        )
                    )
                )
            );
    }

    function rewards_address() internal returns (address) {
        return
            address(
                uint160(
                    uint256(
                        hevm.load(
                            address(comitium),
                            bytes32(uint256(COMITIUM_STORAGE_POSITION) + 5)
                        )
                    )
                )
            );
    }

    function setUp() public {
        // Make `this` comitium owner
        hevm.store(
            address(comitium),
            bytes32(uint256(DIAMOND_STORAGE_POSITION) + 3),
            bytes32(uint256(address(this)))
        );
        assertEq(owner(), address(this));

        // Make `this` FDT owner
        hevm.store(
            address(fdt),
            bytes32(uint256(6)),
            bytes32(uint256(address(this)))
        );
        assertEq(fdt.owner(), address(this));

        // Mint some FDT tokens
        fdt.mint(address(this), 100e18);
    }

    function test_claim() public {
        // Start of rewards
        hevm.warp(1636934400);
        hevm.roll(13984334);
        
        // Set current multiplier to something older
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(0xcf02602e4cb74e2 - 100))
        );        

        // Approve tokens
        fdt.approve(address(comitium), fdt.balanceOf(address(this)));

        // 
        uint256 userMultiplier0 = rewards.userMultiplier(address(this));

        // Deposit tokens
        comitiumFacet.deposit(fdt.balanceOf(address(this)));

        // Forward time
        hevm.warp(1647255769);
        hevm.roll(14384340);

        // Set current multiplier to current
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(0xcf02602e4cb74e2))
        );         

        // Withdraw tokens
        comitiumFacet.withdraw(comitiumFacet.balanceOf(address(this)));

        // Claim rewards
        uint256 amount = rewards.claim();
        emit log_uint(amount);
    }
}
