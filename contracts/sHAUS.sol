// SPDX-License-Identifier: MIT
// contracts/sHAUS.sol

pragma solidity ^0.8.21;

import "solady/src/tokens/ERC20.sol";
import "solady/src/auth/Ownable.sol";
import "solady/src/utils/FixedPointMathLib.sol";
import "solady/src/utils/UUPSUpgradeable.sol";

contract sHAUS is ERC20, Ownable, UUPSUpgradeable {
    using FixedPointMathLib for uint256;

    // Addresses and percentages for protocol operations
    address public protocolFeeAddress;
    uint256 public protocolFeePercentage;
    uint256 public burnPercentage;
    
    // S-curve parameters
    uint256 public L;  // Upper asymptote
    uint256 public k;  // Steepness
    uint256 public x0;  // X-axis midpoint

    // Reentrancy state variable
    bool private locked;

    // Proposal structure
    struct Proposal {
        string description;
        bytes4 functionSig;
        bytes arguments;
        uint256 deadline;
        uint256 forVotes;
        uint256 againstVotes;
    }

    Proposal[] public proposals;

    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 issuedTokens);
    event TaxedTransaction(address indexed from, address indexed to, uint256 tax, uint256 burned);

    constructor(
        address _protocolFeeAddress,
        uint256 _protocolFeePercentage,
        uint256 _burnPercentage,
        uint256 _L,
        uint256 _k,
        uint256 _x0
    ) ERC20("sHAUS", "sHAUS") {
        protocolFeeAddress = _protocolFeeAddress;
        protocolFeePercentage = _protocolFeePercentage;
        burnPercentage = _burnPercentage;
        L = _L;
        k = _k;
        x0 = _x0;
    }

    // Implement S-curve logic for pricing
    function calculatePrice(uint256 x) public view returns (uint256) {
        return L / (1 + (x / x0) ** (-k));
    }

    // Reentrancy guard
    modifier noReentrancy() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // Update transfer to use S-curve and add reentrancy guard
    function transfer(address to, uint256 amount) public override noReentrancy returns (bool) {
        uint256 taxAmount = (amount * protocolFeePercentage) / 100;
        uint256 burnAmount = (amount * burnPercentage) / 100;

        // Transfer tax to protocol fee address
        super.transfer(protocolFeeAddress, taxAmount);
        // Burn tokens
        _burn(msg.sender, burnAmount);
        // Transfer remaining tokens
        super.transfer(to, amount - taxAmount - burnAmount);

        emit TaxedTransaction(msg.sender, to, taxAmount, burnAmount);

        return true;
    }

    // Implement deposit method to use S-curve
    function deposit(uint256 amountETH) public payable {
        require(msg.value == amountETH, "Invalid amount sent");
        
        uint256 issuedTokens = calculatePrice(amountETH);
        
        // Mint new tokens for the user
        _mint(msg.sender, issuedTokens);

        emit Deposited(msg.sender, amountETH, issuedTokens);
    }

    // Override the _authorizeUpgrade method for upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Only the owner can upgrade the contract
    }

    // DAO Governance functions
    // TODO
    // Need to review this
    // DAO should only be able to change the percentages in the surve and slope.
    // maybe looking into contract pausing.
    // might scrap all this anyway.
    

    function createProposal(string memory description, bytes4 functionSig, bytes memory arguments, uint256 duration) public onlyOwner {
        Proposal memory newProposal;
        newProposal.description = description;
        newProposal.functionSig = functionSig;
        newProposal.arguments = arguments;
        newProposal.deadline = block.timestamp + duration;
        proposals.push(newProposal);
    }

    function vote(uint256 proposalId, bool support) public onlyOwner {
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposals[proposalId].forVotes += 1;
        } else {
            proposals[proposalId].againstVotes += 1;
        }
    }

    function executeProposal(uint256 proposalId) public onlyOwner {
        require(proposals[proposalId].deadline < block.timestamp, "Voting period not over");

        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.forVotes > proposal.againstVotes, "Proposal not passed");

        (bool success,) = address(this).call(abi.encodeWithSelector(proposal.functionSig, proposal.arguments));
        require(success, "Proposal execution failed");
    }
}
