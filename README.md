# Project: SpaceCoin ICO 

## Overview

Welcome to the SpaceCoin ICO project! In this project, we have created an ERC-20 token called SpaceCoin (`SPC`) and an ICO contract to facilitate the Initial Coin Offering. Below are the details of the implemented contracts, deployment instructions, and other relevant information.

## Implemented Contracts

1. **SpaceCoin Token Contract**: This contract implements the ERC-20 standard using OpenZeppelin's ERC20.sol library. SpaceCoin has a maximum total supply of 500,000 tokens, with 150,000 tokens allocated to the ICO contract and the remaining 350,000 tokens minted to the treasury account.

2. **ICO Contract**: The ICO contract facilitates three phases (SEED, GENERAL, OPEN) of the token sale, each with specific contribution limits and functionality. Contributors can exchange ETH for SPC tokens at a ratio of 1:5 during the OPEN phase.

    <br>
    <details>
    <summary>ICO Phases</summary>

    | Phase   | Description                                                                                                                          |
    | ------- | ------------------------------------------------------------------------------------------------------------------------------------ |
    | SEED    | - Restricted to addresses in the allowlist<br> - Individual contribution limit: 1,500 ETH<br> - Total contributors limit: 15,000 ETH |
    | GENERAL | - Open to any address<br> - Individual contribution limit: 1,000 ETH<br> - Total contributors limit: 30,000 ETH                      |
    | OPEN    | - Open to any address<br> - Total contributors limit: 30,000 ETH                                                                     |

    </details>
    <br>

## Main Functionalities

### Transaction Fee
- The SpaceCoin token charges a tax on every transfer, which can be toggled on/off by the contract owner.
- The tax is deducted from the transferred amount and sent to the treasury.

### Contribution
- The ICO contract allows address to contribute ETH during the SEED, GENERAL, and OPEN phases (some stages have restrictions on who can contribute).
- Contribution limits are enforced for each phase, with individual and total contribution limits. Individual and total contributions are transmitted through the phases.


### Redemption
- Contributors can redeem their ETH for SpaceCoin tokens at a ratio of 1:5 during the OPEN phase.



## Testnet Deployment and Etherscan Verification

The contracts have been deployed to the Sepolia testnet and verified on Etherscan.

1. **SpaceCoin Contract**: [Etherscan link](https://sepolia.etherscan.io/address/0xSPACECOIN)
2. **ICO Contract**: [Etherscan link](https://sepolia.etherscan.io/address/0xSPACEICO)


## Code Coverage Report

**Code coverage details:**

| File                   | % Lines         | % Statements     | % Branches     | % Funcs         |
| ---------------------- | --------------- | ---------------- | -------------- | --------------- |
| script/DeploySPC.s.sol | 100.00% (7/7)   | 100.00% (9/9)    | 100.00% (0/0)  | 100.00% (1/1)   |
| src/Ico.sol            | 98.46% (64/65)  | 98.68% (75/76)   | 90.48% (38/42) | 100.00% (14/14) |
| src/SpaceCoin.sol      | 100.00% (21/21) | 100.00% (26/26)  | 100.00% (6/6)  | 100.00% (9/9)   |
| Total                  | 98.92% (92/93)  | 99.10% (110/111) | 91.67% (44/48) | 100.00% (24/24) |

## Future Work

While the current implementation meets the project requirements, there are several features that could be added in the future:

- **Witdhraw:** Implementing withdrawal functionality for the ICO treasury.
- **Security:** Enhancing security measures such as access control and error handling.
- **Referral Program:** Introduce a referral program where existing contributors are rewarded with additional tokens for referring new participants to the ICO, fostering community growth and engagement.
- **Governance Framework:** Develop a governance framework that allows token holders to vote on important decisions such as protocol upgrades, allocation of funds from the treasury, or changes to token parameters.
- **Staking Rewards:** Introduce staking functionality where token holders can lock up their tokens to earn rewards, incentivizing long-term holding and participation in the network.

