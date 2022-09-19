// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract Web3MSUDAO is Ownable, ERC20 {

address ownerPayable = payable(owner());

constructor() ERC20("Web3MSU", "MSU") {
    mint(ownerPayable, 10000);
}

function mint(address to, uint amount) internal {
    _mint(to,amount);
}

// Create a struct named mintProposal containing all relevant information
struct Proposal {

    // proposalType - type of proposal, [0] = mint proposal, [1] proposal to send ether
    uint256 proposalType;
    // description - string description of proposal
    string description;
    // reciever - recieving address of proposal
    address reciever;
    // amount - amount of tokens to mint
    uint amount;
    // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
    uint256 deadline;
    // yayVotes - number of yay votes for this proposal
    uint256 yayVotes;
    // nayVotes - number of nay votes for this proposal
    uint256 nayVotes;
    // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
    bool executed;
    // voters - a mapping of token holders to booleans indicating whether they have voted or not
    mapping(uint256 => bool) voters;

}


// Create a mapping of ID to Mint Proposal
mapping(uint256 => Proposal) public Proposals;

// Number of proposals that have been created
uint256 public numProposals;

// Create a modifier which only allows a function to be
// called by someone who owns at least 1 Web3MSU token
modifier tokenHolderOnly() {
    require(balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
    _;
}

// @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
// @return Returns the proposal index for the newly created proposal

function createProposal(uint _proposalType, address _reciever, string memory _description)
    external
    tokenHolderOnly
    returns (uint256)
{

    Proposal storage proposal = Proposals[numProposals];
    proposal.proposalType = _proposalType;
    proposal.reciever = _reciever;
    proposal.description = _description;

    // Set the proposal's voting deadline to be (current time + 7 days)
    proposal.deadline = block.timestamp + 7 days;
    numProposals++;
    return numProposals - 1;
}


// Create a modifier which only allows a function to be
// called if the given proposal's deadline has not been exceeded yet
modifier activeProposalOnly(uint256 proposalIndex) {
    require(
        Proposals[proposalIndex].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
    );
    _;
}


// Create an enum named Vote containing possible options for a vote
enum Vote {
    YAY, // YAY = 0
    NAY // NAY = 1
}


//@dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
//@param proposalIndex - the index of the proposal to vote on in the proposals array
// @param vote - the type of vote they want to cast
function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    tokenHolderOnly
    activeProposalOnly(proposalIndex)
{
    Proposal storage proposal = Proposals[proposalIndex];
    
    uint256 votingPower = balanceOf(msg.sender);

   //add a require statement that will check if a user has voted or not
    if (vote == Vote.YAY) {
        proposal.yayVotes += votingPower;
    } else {
        proposal.nayVotes += votingPower;
    }

}


//execute proposal function
function executeProposal(uint proposalIndex) public tokenHolderOnly {
    Proposal storage proposal = Proposals[proposalIndex];
    if (proposal.yayVotes > proposal.nayVotes && proposal.proposalType == 0) {
        mint(proposal.reciever,proposal.amount);
    }
    else if (proposal.yayVotes > proposal.nayVotes && proposal.proposalType == 1) {
        payable(proposal.reciever).transfer(proposal.amount);
    }
}


// Create a modifier which only allows a function to be
// called if the given proposals' deadline HAS been exceeded
// and if the proposal has not yet been executed
modifier inactiveProposalOnly(uint256 proposalIndex) {
    require(
        Proposals[proposalIndex].deadline <= block.timestamp,
        "DEADLINE_NOT_EXCEEDED"
    );
    require(
        Proposals[proposalIndex].executed == false,
        "PROPOSAL_ALREADY_EXECUTED"
    );
    _;
}

/// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract

function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
}


// The following two functions allow the contract to accept ETH deposits
// directly from a wallet without calling a function

receive() external payable {}

fallback() external payable {}





}

