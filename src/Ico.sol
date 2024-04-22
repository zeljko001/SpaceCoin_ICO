// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SpaceCoin} from "./SpaceCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Ico is ReentrancyGuard {
    error Ico__NotOwner();
    error Ico__IndividualContributionLimitError();
    error Ico__TotalContributionLimitError();
    error Ico__NotInAllowlist();
    error Ico__NotAllowToContribute();
    error Ico__NotAllowToRedeem();
    error Ico__CanNotUprgadePhases();
    error Ico__WrongCurrentContributionStatus();
    error Ico__WrongCurrentRedeemStatus();

    event PhaseChanged(Phases newPhase);
    event Contribution(address indexed contributor, uint256 ContributionAmount);
    event Redeeming(address indexed redeemer, uint256 amount);

    enum Phases {
        SEED,
        GENERAL,
        OPEN
    }

    Phases private s_certainPhase;
    mapping(address => uint256) private s_addressToAmountContribution;
    address[] private s_contributorsList;
    address[] private s_allowlist;
    uint256 private s_totalContribution;
    bool private s_canContribute;
    bool private s_canRedeem;

    uint256 private constant INDIVIDUAL_CONTRIBUTION_LIMIT_SEED = 1500 ether;
    uint256 private constant TOTAL_CONTRIBUTORS_LIMIT_SEED = 15000 ether;
    uint256 private constant INDIVIDUAL_CONTRIBUTION_LIMIT_GENERAL = 1000 ether;
    uint256 private constant TOTAL_CONTRIBUTORS_LIMIT_GENERAL = 30000 ether;
    uint256 private constant TOTAL_CONTRIBUTORS_LIMIT_OPEN = 30000 ether;
    uint256 private constant ICO_EXCANGE_RATE = 5;

    address private immutable i_owner;
    SpaceCoin public immutable i_spc;

    constructor(address _owner, SpaceCoin _spc) {
        i_owner = _owner;
        i_spc = _spc;
        s_certainPhase = Phases.SEED;
        s_allowlist.push(0xb6A3aab73340CcF11b3cd6B9182d129Ff1Bfe6D0);
        s_allowlist.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        s_canContribute = true;
        s_canRedeem = true;
    }

    modifier OnlyOwner() {
        if (msg.sender != i_owner) {
            revert Ico__NotOwner();
        }
        _;
    }

    modifier isContributionAllowed() {
        if (s_canContribute == false) {
            revert Ico__NotAllowToContribute();
        }
        _;
    }

    modifier isRedeemAllowed() {
        if (s_canRedeem == false) {
            revert Ico__NotAllowToRedeem();
        }
        _;
    }

    /**
     * @param currentCanContribute this is the current contribution permission status
     * @dev This function allows to owner to change contribution permission status
     */
    function changeContributionPermission(bool currentCanContribute) external OnlyOwner {
        if (currentCanContribute == s_canContribute) {
            s_canContribute = !s_canContribute;
        } else {
            revert Ico__WrongCurrentContributionStatus();
        }
    }

    /**
     * @param currentCanRedeem this is the current redeem permission status
     * @dev This function allows to owner to change redeem permission status
     */
    function changeRedeemPermission(bool currentCanRedeem) external OnlyOwner {
        if (currentCanRedeem == s_canRedeem) {
            s_canRedeem = !s_canRedeem;
        } else {
            revert Ico__WrongCurrentRedeemStatus();
        }
    }

    /**
     * @param phaseChecker this is the current phase
     * @dev This function allows the ICO phase to be upgraded
     * @dev Protects the user from accidental double upgrade
     */
    function upgradeStatus(Phases phaseChecker) external OnlyOwner {
        if (s_certainPhase != phaseChecker) {
            revert Ico__CanNotUprgadePhases();
        }
        if (s_certainPhase == Phases.SEED) {
            s_certainPhase = Phases.GENERAL;
            emit PhaseChanged(s_certainPhase);
        } else if (s_certainPhase == Phases.GENERAL) {
            s_certainPhase = Phases.OPEN;
            emit PhaseChanged(s_certainPhase);
        }
    }

    /**
     * @dev This function enables contibution in our SpaceCoin
     * @dev It takes care of limits on contributor lvl and total contribution too, depending on the phase of our ICO
     * @dev Here we got 3 conditions, each one for certain phase
     * @dev After fulfilling all those conditions, we call internal function contributeProccess()
     */
    function contribute() external payable isContributionAllowed {
        if (s_certainPhase == Phases.SEED) {
            if (msg.value + s_addressToAmountContribution[msg.sender] > INDIVIDUAL_CONTRIBUTION_LIMIT_SEED) {
                revert Ico__IndividualContributionLimitError();
            }
            if (msg.value + s_totalContribution > TOTAL_CONTRIBUTORS_LIMIT_SEED) {
                revert Ico__TotalContributionLimitError();
            }
            if (!(isInAllowList(msg.sender))) {
                revert Ico__NotInAllowlist();
            }
            contributeProccess();
        } else if (s_certainPhase == Phases.GENERAL) {
            if (msg.value + s_addressToAmountContribution[msg.sender] > INDIVIDUAL_CONTRIBUTION_LIMIT_GENERAL) {
                revert Ico__IndividualContributionLimitError();
            }
            if (msg.value + s_totalContribution > TOTAL_CONTRIBUTORS_LIMIT_GENERAL) {
                revert Ico__TotalContributionLimitError();
            }
            contributeProccess();
        } else if (s_certainPhase == Phases.OPEN) {
            if (msg.value + s_totalContribution > TOTAL_CONTRIBUTORS_LIMIT_OPEN) {
                revert Ico__TotalContributionLimitError();
            }
            contributeProccess();
        }
    }

    /**
     * @dev This function represents the logic of how contribution is working
     */
    function contributeProccess() internal {
        require(msg.value > 0, "You need to spend more ETH!");
        s_addressToAmountContribution[msg.sender] += msg.value;
        s_totalContribution += msg.value;
        if (!(isInContributorsList(msg.sender))) {
            s_contributorsList.push(msg.sender);
        }
        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev This function allows the user, depending on how much he has contributed in the previous phases,
     *  to reedem the amount of SpaceCoin in OPEN phase
     */
    function redeem() external nonReentrant isRedeemAllowed {
        uint256 redeemValue;
        bool success = false;
        if (s_certainPhase == Phases.OPEN && isInContributorsList(msg.sender)) {
            redeemValue = s_addressToAmountContribution[msg.sender] * ICO_EXCANGE_RATE;
            success = i_spc.transfer(msg.sender, redeemValue);
            s_totalContribution = s_totalContribution - s_addressToAmountContribution[msg.sender];
            s_addressToAmountContribution[msg.sender] = 0;
        } else {
            if (s_certainPhase != Phases.OPEN) revert Ico__NotAllowToRedeem();
            else revert Ico__NotInAllowlist();
        }
        if (success) {
            emit Redeeming(msg.sender, redeemValue);
        }
    }

    /**
     * @param contributer address that we want to check
     * @dev This function checks if the given address is allowed to contribute in SEED phase
     */
    function isInAllowList(address contributer) internal view returns (bool) {
        uint256 allowlistLength = s_allowlist.length;
        for (uint256 contributeIndex = 0; contributeIndex < allowlistLength; contributeIndex++) {
            if (contributer == s_allowlist[contributeIndex]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @param contributer address that we want to check
     * @dev This function checks if the given address is in contribution list
     */
    function isInContributorsList(address contributer) internal view returns (bool) {
        uint256 allowlistLength = s_contributorsList.length;
        for (uint256 contributeIndex = 0; contributeIndex < allowlistLength; contributeIndex++) {
            if (contributer == s_contributorsList[contributeIndex]) {
                return true;
            }
        }
        return false;
    }

    ///////////////////////////////////////////
    ////////////////GETERS/////////////////////
    ///////////////////////////////////////////

    function getCertainePhases() public view returns (Phases) {
        return s_certainPhase;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getContributors() public view returns (address[] memory) {
        return s_contributorsList;
    }

    function getAllowList() public view returns (address[] memory) {
        return s_allowlist;
    }

    function getTotalContribution() public view returns (uint256) {
        return s_totalContribution;
    }

    function getRedeemAlowness() public view returns (bool) {
        return s_canRedeem;
    }
}
