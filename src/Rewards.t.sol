// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "ds-test/test.sol";
import {Hevm} from "./test/utils/Hevm.sol";

import {Rewards} from "lib/comitium/contracts/Rewards.sol";
import {Comitium} from "lib/comitium/contracts/Comitium.sol";
import {ComitiumFacet} from "lib/comitium/contracts/facets/ComitiumFacet.sol";
import {ChangeRewardsFacet} from "lib/comitium/contracts/facets/ChangeRewardsFacet.sol";
import {ICommunityVault} from "./ICommunityVault.sol";

import {ComitiumFacetNew} from "./comitium/ComitiumFacetNew.sol";
import {IDiamondCut} from "lib/comitium/contracts/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "lib/comitium/contracts/facets/DiamondCutFacet.sol";

import {FDT} from "./FDT.sol";

contract RewardsTest is DSTest {
    // Cheat codes
    Hevm internal hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    ICommunityVault private communityVault = ICommunityVault(0x34d53E1aF009fFDd6878413CC8E83D5a6906B8cB);

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
    ChangeRewardsFacet private changeRewardsFacet = ChangeRewardsFacet(address(comitium));

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

        hevm.store(address(communityVault), bytes32(uint256(0)), bytes32(uint256(address(this))));
        assertEq(communityVault.owner(), address(this));

        // Mint some FDT tokens
        fdt.mint(address(this), 1e18);
    }

    function test_claim() public {
        // Set current multiplier to something older
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(100))
        );        

        // Approve tokens
        fdt.approve(address(comitium), fdt.balanceOf(address(this)));

        // Deposit tokens
        comitiumFacet.deposit(fdt.balanceOf(address(this)));

        //
        uint256 userMultiplier0 = rewards.userMultiplier(address(this));

        // Set current multiplier to current
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(101))
        );         

        // Withdraw tokens
        comitiumFacet.withdraw(comitiumFacet.balanceOf(address(this)));

        uint256 userMultiplier1 = rewards.userMultiplier(address(this));

        emit log_uint(userMultiplier0);
        emit log_uint(userMultiplier1);

        // Claim rewards
        uint256 amount = rewards.claim();
        emit log_uint(amount);
    }

    function test_setNewRewards() public {
        Rewards rewardsNew = new Rewards(address(this), address(fdt), address(comitium));
        rewardsNew.setupPullToken(address(communityVault), 1646611201, 1654555389, 4300000000000000000000000);
        communityVault.setAllowance(address(rewardsNew), 4300000000000000000000000);

        // Change rewards contract was updated
        changeRewardsFacet.changeRewardsAddress(address(rewardsNew));
        assertEq(address(rewardsNew), rewards_address());

        // Without comitium upgrade we should still be able to withdraw from the old rewards contract
        // test_claim();

        // Set current multiplier to reward contracts
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(100))
        );
        hevm.store(
            address(rewardsNew),
            bytes32(uint256(0x9)),
            bytes32(uint256(100))
        );

        // Approve tokens
        fdt.approve(address(comitium), fdt.balanceOf(address(this)));

        // Deposit tokens
        comitiumFacet.deposit(fdt.balanceOf(address(this))); 

        // Current multipliers
        uint256 userMultiplier0 = rewards.userMultiplier(address(this));
        uint256 userMultiplier1 = rewardsNew.userMultiplier(address(this));

        emit log_uint(userMultiplier0);
        emit log_uint(userMultiplier1);
    }

    function test_setNewRewards_withUpdatedComitium() public {
        // Current multipliers
        uint256 userMultiplierBefore0 = rewards.userMultiplier(address(this));
        emit log_uint(userMultiplierBefore0);

        // Set up a new rewards
        Rewards rewardsNew = new Rewards(address(this), address(fdt), address(comitium));
        rewardsNew.setupPullToken(address(communityVault), 1646611201, 1654555389, 4300000000000000000000000);
        communityVault.setAllowance(address(rewardsNew), 4300000000000000000000000);


        // Deploy new ComitiumFacet
        ComitiumFacetNew comitiumFacetNew = new ComitiumFacetNew();

        // Define new diamond facets
        IDiamondCut.FacetCut[] memory fc = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](2);
        functionSelectors[0] = comitiumFacetNew.deposit.selector;
        functionSelectors[1] = comitiumFacetNew.withdraw.selector;
        fc[0] = IDiamondCut.FacetCut({
            facetAddress: address(comitiumFacetNew),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: functionSelectors
        });

        // Set new facets for
        DiamondCutFacet dcf = DiamondCutFacet(address(comitium));
        dcf.diamondCut(
            fc,
            address(0),
            bytes("")
        );
        bytes memory changeFacet = abi.encodeWithSelector(dcf.diamondCut.selector, fc,
            address(0),
            bytes("")
        );
        emit log_bytes(changeFacet);

        // Change rewards contract was updated
        changeRewardsFacet.changeRewardsAddress(address(rewardsNew));
        assertEq(address(rewardsNew), rewards_address());

        // Without comitium upgrade we should still be able to withdraw from the old rewards contract
        // test_claim();

        // Set current multiplier to reward contracts
        hevm.store(
            address(rewards),
            bytes32(uint256(0x9)),
            bytes32(uint256(100))
        );
        hevm.store(
            address(rewardsNew),
            bytes32(uint256(0x9)),
            bytes32(uint256(100))
        );

        // Approve tokens
        fdt.approve(address(comitium), fdt.balanceOf(address(this)));

        // Deposit tokens
        comitiumFacet.deposit(fdt.balanceOf(address(this))); 

        // Current multipliers
        uint256 userMultiplier0 = rewards.userMultiplier(address(this));
        uint256 userMultiplier1 = rewardsNew.userMultiplier(address(this));
        emit log_uint(userMultiplier0);
        emit log_uint(userMultiplier1);
    }
}
