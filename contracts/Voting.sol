pragma solidity ^0.5.8;

contract Ownable {
   address public owner;

   constructor () public{
       owner = msg.sender;
   }

   modifier onlyOwner {
       require(msg.sender == owner, "Votante no autorizado.");
       _;
   }
}


contract Voting is Ownable {
    // Candidates map
    uint8 private candidatesListCounter = 0;
    uint8[9] private cantidateListId;
    bytes32[9] private cantidateListName;
    uint8[9] private candidateListVotes;
    // Candidates utilities
    mapping(bytes32 => bool) private candidateValidator;

    // Voters map
    uint8[28] private votersListId;
    bytes32[28] private votersListIdentification;
    bytes32[28] private votersListName;
    // Voters utilities
    mapping(bytes32 => address) private votersListAddressMap;
    mapping(bytes32 => uint8) private votersListValidator;
    mapping(bytes32 => bool) private votersListVoted;
    mapping(address => uint8) private votersListIdMap;

    // Voting starter and finisher
    bool votingIsOpen;

    // Events
    event AddedCandidate(bytes32 candidateStored);
    event AddedVote(bytes32 candidateName, uint8 candidateVotes);

    /**
     * Constructor. Initialize the voters.
     */
    constructor(uint8[28] memory _votersListId,
                bytes32[28] memory _votersListIdentification,
                bytes32[28] memory _votersListName,
                uint8[9] memory _cantidateListId,
                bytes32[9] memory _cantidateListName) public {

        // Voters initialization
        votersListId = _votersListId;
        votersListIdentification = _votersListIdentification;
        votersListName = _votersListName;
        for( uint8 i = 0 ; i < 28; i++){
            votersListValidator[votersListIdentification[i]] = 1;
        }

        // Candidates initialization
        cantidateListId = _cantidateListId;
        cantidateListName = _cantidateListName;
        for( uint8 i = 0 ; i < 9; i++){
            candidateListVotes[i] = 0;
        }
    }

    modifier onlyNewCandidate(bytes32 _candidate){
        require(candidateValidator[_candidate] != true, "Candidato solo puede ser a??adido una sola vez.");
        _;
    }

    modifier onlyValidVoter(bytes32 _voterIdentification){
        require(votersListValidator[_voterIdentification] == 1, "Votante solo puede ser verificado una sola vez.");
        _;
    }

    function getCandidates() external view returns(uint8[9] memory, bytes32[9] memory) {
        return (cantidateListId, cantidateListName);
    }

    function getCandidateVotes(uint8 _candidateId) external view returns(uint8) {
        require(votingIsOpen == false, "Solo se pueden ver los votos cuando la votaci??n est?? cerrada.");
        return candidateListVotes[_candidateId];
    }

    function getCandidatesVotes() external view returns(bytes32[9] memory, uint8[9] memory) {
        require(votingIsOpen == false, "Solo se pueden ver los votos cuando la votaci??n est?? cerrada.");
        return (cantidateListName, candidateListVotes);
    }

    function associateUserToAddress(bytes32 _voterIdentification) external onlyValidVoter(_voterIdentification) returns(address, bytes32) {
        votersListAddressMap[_voterIdentification] = msg.sender;
        votersListValidator[_voterIdentification] = 2;
        return (msg.sender, _voterIdentification);
    }

    function addCandidate(bytes32 _candidate) internal onlyOwner onlyNewCandidate(_candidate)  {
        // Storing candidate
        cantidateListId[candidatesListCounter] = candidatesListCounter;
        cantidateListName[candidatesListCounter] = _candidate;
        candidateListVotes[candidatesListCounter] = 0;

        // Adding the validator to true for next try
        candidateValidator[_candidate] = true;

        // Adds a new list counter for the next candidate
        candidatesListCounter = candidatesListCounter + 1;
        emit AddedCandidate(_candidate);
    }

    function vote(uint8 _candidateId, bytes32 _voterIdentification)  external {
        // Validadtions
        require(votingIsOpen == true, "Solo se puede votar cuando el tiempo de votaci??n este activo.");
        require(votersListAddressMap[_voterIdentification] == msg.sender, "El votante solo puede votar usando una el address que valid??.");
        require(votersListValidator[_voterIdentification] == 2, "Votante debe haber sido validado.");
        require(votersListVoted[_voterIdentification] == false, "Votante solo puede votar una vez.");

        // Incrementing voting count
        uint8 _candidateCount = candidateListVotes[_candidateId] + 1;

        // Removing the possibility for this voter to vote again
        votersListVoted[_voterIdentification] = true;
       votersListValidator[_voterIdentification] = 3;

        // Asigning the new votes to the candidate
        candidateListVotes[_candidateId] = _candidateCount;

        emit AddedVote(cantidateListName[_candidateId], _candidateCount);
    }

    function initializeVoting() external onlyOwner {
        votingIsOpen = true;
    }

    function finishVoting() external onlyOwner {
        votingIsOpen = false;
    }

    function getVotingStatus() external view returns(bool) {
        return votingIsOpen;
    }

    function() external payable {}
}