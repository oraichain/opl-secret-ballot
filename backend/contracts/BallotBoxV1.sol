// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol"; // solhint-disable-line no-global-import

contract BallotBoxV1 {
    error NotPublishingVotes();
    error AlreadyVoted();
    error UnknownChoice();

    struct Ballot {
        bool active;
        ProposalParams params;
        /// voter -> choice id
        mapping(address => Choice) votes;
        /// choice id -> vote
        uint256[32] voteCounts;
    }

    struct Choice {
        bool exists;
        uint8 choice;
    }

    event BallotClosed(ProposalId indexed id, uint256 topChoice);

    address _owner;
    mapping(ProposalId => Ballot) private _ballots;

    constructor() {
        _owner = msg.sender; // Casting vote should be allowed by the owner only (usually DAO contract).
    }

    function castVote(
        ProposalId proposalId,
        uint256 choiceIdBig
    ) external {
        require(msg.sender==_owner);
        Ballot storage ballot = _ballots[proposalId];
        if (!ballot.active) revert NotActive();
        uint8 choiceId = uint8(choiceIdBig & 0xff);
        if (choiceId >= ballot.params.numChoices) revert UnknownChoice();
        Choice memory existingVote = ballot.votes[msg.sender];
        // 1 click 1 vote
        for (uint256 i; i < ballot.params.numChoices; ++i) {
            // read-modify-write all counts to make it harder to determine which one is chosen.
            ballot.voteCounts[i] ^= 1 << 255; // flip the top bit to constify gas usage a bit
            // Arithmetic is not guaranteed to be constant time, so this might still leak the choice to a highly motivated observer.
            ballot.voteCounts[i] += i == choiceId ? 1 : 0;
            ballot.voteCounts[i] -= existingVote.exists && existingVote.choice == i
            ? 1
            : 0;
        }
        ballot.votes[msg.sender].exists = true;
        ballot.votes[msg.sender].choice = choiceId;
    }

    function closeBallot(ProposalId proposalId) public payable returns (uint256) {
        Ballot storage ballot = _ballots[proposalId];
        if (!ballot.active) revert NotActive();

        uint256 topChoice;
        uint256 topChoiceCount;
        for (uint8 i; i < ballot.params.numChoices; ++i) {
            uint256 choiceVoteCount = ballot.voteCounts[i] & (type(uint256).max >> 1);
            if (choiceVoteCount > topChoiceCount) {
                topChoice = i;
                topChoiceCount = choiceVoteCount;
            }
        }
        delete _ballots[proposalId];
        return topChoice;
    }

    function getVoteOf(ProposalId proposalId, address voter) external view returns (Choice memory) {
        Ballot storage ballot = _ballots[proposalId];
        if (voter == msg.sender) return ballot.votes[msg.sender];
        if (!ballot.params.publishVotes) revert NotPublishingVotes();
        return ballot.votes[voter];
    }

    function ballotIsActive(ProposalId id) external view returns (bool) {
        return _ballots[id].active;
    }

    function createBallot(bytes calldata args) public {
        (ProposalId id, ProposalParams memory params) = abi.decode(
            args,
            (ProposalId, ProposalParams)
        );
        Ballot storage ballot = _ballots[id];
        ballot.params = params;
        ballot.active = true;
        for (uint256 i; i < params.numChoices; ++i) ballot.voteCounts[i] = 1 << 255; // gas usage side-channel resistance.
    }
}
