// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeploySPC} from "../script/DeploySPC.s.sol";
import {Ico} from "../src/Ico.sol";
import {SpaceCoin} from "../src/SpaceCoin.sol";

contract ProtocolTest is Test {
    Ico ico;
    SpaceCoin spc;
    DeploySPC deployer;

    address public USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 3000 ether;
    uint256 constant TAX_PERCENTAGE = 2;
    uint256 private constant ICO_EXCANGE_RATE = 5;

    function setUp() public {
        deployer = new DeploySPC();
        (spc, ico) = deployer.run();
    }

    function testSpaceCoinBeginingMinting() public view {
        address treasury = spc.getTreasury();
        uint256 expectedTotalMinted = spc.totalSupply();
        uint256 treasuryMinted = spc.balanceOf(treasury);
        uint256 icoMinted = spc.balanceOf(address(ico));
        assert((icoMinted + treasuryMinted) == expectedTotalMinted);
    }

    function testIcoAndSpcOwnerIsEqual() public view {
        assert(ico.getOwner() == spc.getOwner());
    }

    function testTransferFromWithTax() public {
        address owner = ico.getOwner();
        address treasury = spc.getTreasury();
        uint256 contributeValue = 100 ether;
        address[] memory allowList = ico.getAllowList();
        uint256 spenderAmountTokenAfterRedeem = ((contributeValue * ICO_EXCANGE_RATE) * (100 - TAX_PERCENTAGE)) / 100;
        uint256 expectUSERAmountOfSpcAfterTransferFrom = (spenderAmountTokenAfterRedeem * (100 - TAX_PERCENTAGE)) / 100;
        uint256 expectTreasuryAmountOfSpcAfterTransferFrom = spc.balanceOf(treasury)
            + ((contributeValue * ICO_EXCANGE_RATE) * TAX_PERCENTAGE) / 100
            + (spenderAmountTokenAfterRedeem * TAX_PERCENTAGE) / 100;

        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        hoax(allowList[0], contributeValue);
        ico.contribute{value: contributeValue}();
        vm.prank(allowList[0]);
        ico.redeem();
        uint256 startSpcSender = spc.balanceOf(allowList[0]);
        vm.prank(allowList[0]);
        spc.approve(owner, startSpcSender);
        vm.prank(owner);
        spc.transferFrom(allowList[0], USER, startSpcSender);
        uint256 endSpenderAmountOfSpc = spc.balanceOf(allowList[0]);
        uint256 endUserAmountOfSpc = spc.balanceOf(USER);
        uint256 endTreasuryAmountOfSpc = spc.balanceOf(treasury);
        assert(expectUSERAmountOfSpcAfterTransferFrom == endUserAmountOfSpc);
        assert(expectTreasuryAmountOfSpcAfterTransferFrom == endTreasuryAmountOfSpc);
        assert(endSpenderAmountOfSpc == 0);
    }

    ////////////////////////////////////////
    ////////////UPGRADE STATUS//////////////
    ////////////////////////////////////////

    function testUpgradeStatus() public {
        address owner = ico.getOwner();
        Ico.Phases startingPhase = ico.getCertainePhases();
        Ico.Phases controlePhase = (Ico.Phases).SEED;
        vm.prank(owner);
        ico.upgradeStatus(controlePhase);
        Ico.Phases endingPhase = ico.getCertainePhases();
        assert(startingPhase != endingPhase);
    }

    function testUpgradeStatusIfWeClickTwoTimes() public {
        address owner = ico.getOwner();
        Ico.Phases startingPhase = ico.getCertainePhases();
        Ico.Phases controlePhase = (Ico.Phases).SEED;
        vm.startPrank(owner);
        ico.upgradeStatus(controlePhase);
        vm.expectRevert();
        ico.upgradeStatus(controlePhase);
        vm.stopPrank();
        Ico.Phases endingPhase = ico.getCertainePhases();
        assert(startingPhase != endingPhase);
    }

    function testOnlyOwnerCanUpgradeStatus() public {
        Ico.Phases controlePhase = (Ico.Phases).SEED;
        vm.prank(USER);
        vm.expectRevert();
        ico.upgradeStatus(controlePhase);
    }

    ////////////////////////////////////////
    ////////////  CONTRIBUTE  //////////////
    ////////////////////////////////////////

    function testGetContributorsAndGetTotalContribution() public {
        address[] memory allowList = ico.getAllowList();
        uint256 startNumberOfCOntributors = (ico.getContributors()).length;
        uint256 startExpectedNumberOfCOntributors = 0;
        uint256 sendValue = 1 ether;
        uint256 expectedTotalContribution = sendValue;
        hoax(allowList[0], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        uint256 endNumberOfCOntributors = (ico.getContributors()).length;
        uint256 endExpectedNumberOfCOntributors = 1;
        assert(startNumberOfCOntributors == startExpectedNumberOfCOntributors);
        assert(endNumberOfCOntributors == endExpectedNumberOfCOntributors);
        assert(ico.getTotalContribution() == expectedTotalContribution);
    }

    function testOnlyUsersInAllowlistCanContributeInSeedPhase() public {
        uint256 sendValue = 1 ether;
        address[] memory allowUsers = ico.getAllowList();
        hoax(allowUsers[1], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        hoax(USER, STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValue}();
    }

    function testContributeZeroEth() public {
        uint256 sendValue = 0 ether;
        address[] memory allowList = ico.getAllowList();
        hoax(allowList[0], STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValue}();
    }

    function testContributionIndividualLimitThroughPhases() public {
        address owner = ico.getOwner();
        uint256 sendValueSeed = 1501 ether;
        uint256 sendValueGeneral = 1001 ether;
        address[] memory allowUsers = ico.getAllowList();

        hoax(allowUsers[0], STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValueSeed}();
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        hoax(USER, STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValueGeneral}();
    }

    function testContributionTotalLimitThroughPhases() public {
        address owner = ico.getOwner();
        uint256 sendValueSeed = 1500 ether;
        uint256 sendValueGeneral = 1000 ether;
        address[] memory allowUsers = ico.getAllowList();
        uint160 startingContributorIndex = 3;
        uint160 numberOfContributors = 30;

        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValueSeed}();
        hoax(allowUsers[1], STARTING_BALANCE);
        ico.contribute{value: sendValueSeed}();
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        for (uint160 i = startingContributorIndex; i < numberOfContributors; i++) {
            hoax(address(i), STARTING_BALANCE);
            ico.contribute{value: sendValueGeneral}();
        }
        hoax(address(numberOfContributors), STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValueGeneral}();
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        hoax(address(numberOfContributors), STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: STARTING_BALANCE}();
    }

    function testContributionIndividualLimitThroughPhasesIsTransmitted() public {
        address owner = ico.getOwner();
        uint256 sendValueSeed = 1100 ether;
        uint256 sendValueGeneral = 1 ether;
        address[] memory allowUsers = ico.getAllowList();

        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValueSeed}();
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        vm.prank(allowUsers[0]);
        vm.expectRevert();
        ico.contribute{value: sendValueGeneral}();
    }

    function testContributionTotalLimitInOpenPhase() public {
        address owner = ico.getOwner();
        uint160 startingContributorIndex = 1;
        uint160 numberOfContributors = 11;

        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        for (uint160 i = startingContributorIndex; i < numberOfContributors; i++) {
            hoax(address(i), STARTING_BALANCE);
            ico.contribute{value: STARTING_BALANCE}();
        }
        hoax(address(numberOfContributors), STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: 0.1 ether}();
    }

    function testChangeContributionAllowness() public {
        address owner = ico.getOwner();
        address[] memory allowUsers = ico.getAllowList();
        uint256 sendValue = 1 ether;
        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        vm.prank(USER);
        vm.expectRevert();
        ico.changeContributionPermission(true);
        vm.prank(owner);
        vm.expectRevert();
        ico.changeContributionPermission(false);
        vm.prank(owner);
        ico.changeContributionPermission(true);
        hoax(allowUsers[0], STARTING_BALANCE);
        vm.expectRevert();
        ico.contribute{value: sendValue}();
    }

    ////////////////////////////////////////
    ////////////    REDEEM    //////////////
    ////////////////////////////////////////

    function testRedeemIfNotOpenPhase() public {
        address owner = ico.getOwner();
        uint256 sendValue = 1 ether;
        address[] memory allowUsers = ico.getAllowList();

        //SEED PHASE
        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        vm.prank(allowUsers[0]);
        vm.expectRevert();
        ico.redeem();
        //GENERAL PHASE
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        vm.prank(allowUsers[0]);
        vm.expectRevert();
        ico.redeem();
        //OPEN PHASE
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        vm.prank(allowUsers[0]);
        ico.redeem();
    }

    function testRedeemIfNotContributeBefore() public {
        address owner = ico.getOwner();
        uint256 sendValue = 100 ether;
        address[] memory allowUsers = ico.getAllowList();

        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        vm.prank(owner);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        vm.prank(USER);
        vm.expectRevert();
        ico.redeem();
        vm.prank(allowUsers[0]);
        ico.redeem();
    }

    function testChangeRedeemAllowness() public {
        address owner = ico.getOwner();
        uint256 sendValue = 100 ether;
        address[] memory allowUsers = ico.getAllowList();
        bool currentRedeemStatus = ico.getRedeemAlowness();
        hoax(allowUsers[0], STARTING_BALANCE);
        ico.contribute{value: sendValue}();
        vm.startPrank(owner);
        ico.upgradeStatus((Ico.Phases).SEED);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        vm.expectRevert();
        ico.changeRedeemPermission(!currentRedeemStatus);
        ico.changeRedeemPermission(currentRedeemStatus);
        vm.stopPrank();
        vm.prank(allowUsers[0]);
        vm.expectRevert();
        ico.redeem();
    }

    function testSetTaxOnOff() public {
        address owner = ico.getOwner();
        bool currentlyTax;
        if (spc.getTax() == false) {
            currentlyTax = false;
        } else {
            currentlyTax = true;
        }
        vm.prank(USER);
        vm.expectRevert();
        spc.setTaxOnOff(currentlyTax);
        vm.prank(owner);
        spc.setTaxOnOff(currentlyTax);
        vm.prank(owner);
        vm.expectRevert();
        spc.setTaxOnOff(currentlyTax);
    }

    function testTransactionsWithoutTax() public {
        address owner = ico.getOwner();
        address treasury = spc.getTreasury();
        uint256 startTreasuryTokenAmount = spc.balanceOf(treasury);
        bool currentlyTax = true;
        vm.deal(owner, STARTING_BALANCE);
        vm.startPrank(owner);
        spc.setTaxOnOff(currentlyTax);
        ico.upgradeStatus((Ico.Phases).SEED);
        ico.upgradeStatus((Ico.Phases).GENERAL);
        ico.contribute{value: STARTING_BALANCE}();
        ico.redeem();
        vm.stopPrank();
        uint256 endTreasuryTokenAmount = spc.balanceOf(treasury);
        uint256 endOwnerTokenAmount = spc.balanceOf(owner);
        assert(startTreasuryTokenAmount == endTreasuryTokenAmount);
        assert(endOwnerTokenAmount == STARTING_BALANCE * ICO_EXCANGE_RATE);
    }
}
