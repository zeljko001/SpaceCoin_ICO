// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; //koristi 0.8.24

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ico} from "./Ico.sol";

contract SpaceCoin is ERC20 {
    error SpaceCoin__NotOwner();
    error SpaceCoin__NotGoodCurrentlyTaxState();

    uint256 public constant TAX_PERCENTAGE = 2;
    bool public s_taxOnOf = true;
    address public immutable i_owner;
    address public immutable i_treasury;
    address public ico;

    constructor(address _treasury) ERC20("SpaceCoin", "SPC") {
        i_owner = msg.sender;
        i_treasury = _treasury;
        ico = address(new Ico(i_owner, this));
        _mint(i_treasury, 350000 * 10 ** 18);
        _mint(ico, 150000 * 10 ** 18);
    }

    modifier OnlyOwner() {
        if (msg.sender != i_owner) {
            revert SpaceCoin__NotOwner();
        }
        _;
    }

    /**
     * @param currentlyTaxOnOf this is the current tax status
     * @dev This function allows to owner to change tax status
     */
    function setTaxOnOff(bool currentlyTaxOnOf) external OnlyOwner {
        if (currentlyTaxOnOf == s_taxOnOf) {
            s_taxOnOf = !s_taxOnOf;
        } else {
            revert SpaceCoin__NotGoodCurrentlyTaxState();
        }
    }

    /**
     * @param amount this is the amount for which we want to calculate the tax percentage
     * @dev This function calculates tax
     */
    function _calculateTax(uint256 amount) internal view returns (uint256) {
        if (s_taxOnOf == true) {
            return (amount * TAX_PERCENTAGE) / 100;
        }
        return 0;
    }

    /**
     * @param from the address from which it is sent
     * @param to address to be sent to
     * @param amount this is the amount which is sent
     * @dev This function carries out transactions according tax is included or not
     */
    function _transferWithTax(address from, address to, uint256 amount) internal {
        uint256 taxAmount = _calculateTax(amount);
        uint256 netAmount = amount - taxAmount;

        if (s_taxOnOf == true) {
            _transfer(from, i_treasury, taxAmount);
        }
        _transfer(from, to, netAmount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transferWithTax(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev To call this function, first we need to approve to caller from spender to send certain amount to recipient
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithTax(from, to, amount);
        return true;
    }

    ///////////////////////////////////////////
    ////////////////GETERS/////////////////////
    ///////////////////////////////////////////

    function getIco() public view returns (Ico) {
        return Ico(ico);
    }

    function getTreasury() public view returns (address) {
        return i_treasury;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getTax() public view returns (bool) {
        return s_taxOnOf;
    }
}
