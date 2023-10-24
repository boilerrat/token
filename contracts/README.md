# sHAUS Smart Contract

## Overview

The `sHAUS` contract is an ERC20 token with additional features for protocol fees, token burns, and an S-curve pricing model for deposits. The contract also supports upgradeability via the UUPS pattern and includes DAO governance capabilities.

## Table of Contents

- [sHAUS Smart Contract](#shaus-smart-contract)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Functions](#functions)
    - [Constructor](#constructor)
    - [Public and External Functions](#public-and-external-functions)
    - [Modifiers](#modifiers)
  - [Events](#events)
  - [DAO Governance](#dao-governance)
    - [Proposal Structure](#proposal-structure)
    - [Governance Functions](#governance-functions)

---

## Features

1. **ERC20 Token**: Inherits standard ERC20 functionality.
2. **Ownable**: Ownership features for privileged operations.
3. **Upgradeable**: UUPS upgradeability.
4. **S-curve Pricing**: For issuing new tokens on deposits.
5. **Reentrancy Guard**: To prevent reentrant attacks.
6. **DAO Governance**: To allow decentralized control over certain parameters.

---

## Functions

### Constructor

- `constructor(address _protocolFeeAddress, uint256 _protocolFeePercentage, uint256 _burnPercentage, uint256 _L, uint256 _k, uint256 _x0)`

  Initializes the contract with protocol settings and S-curve parameters.

### Public and External Functions

- `calculatePrice(uint256 x) -> uint256`

  Calculates the number of tokens to issue for a given amount of ETH based on the S-curve.

- `transfer(address to, uint256 amount) -> bool`

  Overrides the standard ERC20 `transfer` to include protocol fees and token burns.

- `deposit(uint256 amountETH)`

  Accepts ETH and issues tokens to the sender based on the S-curve pricing.

- `createProposal(string description, bytes4 functionSig, bytes arguments, uint256 duration)`

  Create a new governance proposal.

- `vote(uint256 proposalId, bool support)`

  Vote on an existing proposal.

- `executeProposal(uint256 proposalId)`

  Execute a proposal that has passed voting.

### Modifiers

- `noReentrancy`

  Prevents reentrant calls to guarded functions.

---

## Events

- `Deposited(address indexed user, uint256 amount, uint256 issuedTokens)`
- `TaxedTransaction(address indexed from, address indexed to, uint256 tax, uint256 burned)`

---

## DAO Governance

### Proposal Structure

- `description`: Text description of the proposal.
- `functionSig`: The function signature that will be called if the proposal passes.
- `arguments`: The arguments that will be passed to the function.
- `deadline`: The time until which the proposal can be voted on.
- `forVotes`: The number of votes in favor of the proposal.
- `againstVotes`: The number of votes against the proposal.

### Governance Functions

- `createProposal`: To create a new proposal.
- `vote`: To vote on an existing proposal.
- `executeProposal`: To execute a proposal that has passed.
