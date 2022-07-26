//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a proof of concept governance contract that
 * is based on democratic voting rather than coin-based
 * voting. To create and vote on a proposal, one would
 * need to have a citizenship for at least half year.
 * NOTE: Not production ready. Citizenship time could
 * be set to any time limit.
 */

import "./DAOCitizenship.sol";

contract Ballot is DAOCitizenship {
    // Struct that represents a single proposal.
    struct Proposal {
        // Proposal name
        string name;
        // Proposal description (Could be emitted)
        string description;
        // Creator of proposal
        address creator;
        // Proposal vote count
        uint256 voteCount;
        // Proposal vote count for supporting proposal
        uint256 yesCount;
        // Proposal vote count for not supporting proposal
        uint256 noCount;
        // Timestamp of start of proposal
        uint256 startAt;
        // Timestamp of end of proposal
        uint256 endAt;
    }

    // Proposal ID that increments by one every time a new proposal is created
    uint256 public proposalCount;

    // Mapping of proposal ID to Proposal
    mapping(uint256 => Proposal) public proposals;

    // Mapping of proposal ID to user address that maps to if they voted or not
    mapping(uint256 => mapping(address => bool)) public voted;

    // Events
    event ProposalCreated(
        address indexed creator,
        string name,
        uint256 creationDate
    );

    event VotedOnProposal(
        uint256 indexed proposalId,
        string name,
        uint256 voteDate
    );

    // Function for citizen to create a proposal
    function createProposal(string memory _name, string memory _description)
        external
    {
        require(
            DAOCitizenship.balanceOf(msg.sender) > 0,
            "Need citizenship to create a proposal"
        );
        // Assuming 1 block per 15 seconds (4 * 60 * 24 * 183)
        require(
            (DAOCitizenship.registrationDate(msg.sender) + 1054080) <
                block.timestamp,
            "Need to be a citizen for at least half a year"
        );

        proposalCount += 1;

        // Proposal ends in a week (4 * 60 * 24 * 7)
        proposals[proposalCount] = Proposal({
            name: _name,
            description: _description,
            creator: msg.sender,
            voteCount: 0,
            yesCount: 0,
            noCount: 0,
            startAt: block.timestamp,
            endAt: block.timestamp + 40320
        });

        emit ProposalCreated(msg.sender, _name, block.timestamp);
    }

    // Function for citizen to vote on a proposal
    // NOTE: Assuming when "yes" when `_choice` = 0
    // and "no" when `_choice` != 0.
    function vote(uint256 _proposalId, uint256 _choice) external {
        require(
            DAOCitizenship.balanceOf(msg.sender) > 0,
            "Need citizenship to vote on proposal"
        );

        require(
            (DAOCitizenship.registrationDate(msg.sender) + 1054080) <
                block.timestamp,
            "Need to be a citizen for at least half a year"
        );

        Proposal storage proposal = proposals[_proposalId];

        require(
            proposal.creator != address(0),
            "Proposal with ID does not exist"
        );
        require(block.timestamp >= proposal.startAt, "Proposal did not start");
        require(block.timestamp <= proposal.endAt, "Proposal ended");
        require(voted[_proposalId][msg.sender] == false, "Already voted");

        voted[_proposalId][msg.sender] = true;

        proposal.voteCount += 1;

        _choice == 0 ? proposal.yesCount += 1 : proposal.noCount += 1;

        emit VotedOnProposal(_proposalId, proposal.name, block.timestamp);
    }

    // Checks if proposal was successful
    function proposalResult(uint256 _proposalId)
        public
        view
        returns (bool _success)
    {
        Proposal memory proposal = proposals[_proposalId];

        require(
            proposal.creator != address(0),
            "Proposal with ID does not exist"
        );
        require(block.timestamp > proposal.endAt, "Proposal did not end");
        // NOTE: Could be a different implementation for a proposal to pass
        if (proposal.voteCount > 15) {
            proposal.yesCount > proposal.noCount
                ? _success = true
                : _success = false;
        } else {
            _success = false;
        }
    }
}
