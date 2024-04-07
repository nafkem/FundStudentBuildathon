// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FundStudent is Pausable,ReentrancyGuard, Ownable {
    IERC20 private _usdtToken;
    uint256 public proposalCount;
    uint256 public proposalDeadline;
    ERC721 private _nftContract;


    struct Proposal {
        uint256 proposalId;
        address student;
        string description;
        ProposalStatus status;
        uint256 imageIPFSHashTranscript;
        uint256 deadline;
        uint256 amount;
        bool isRegistered;
        bool approved;
        bool disbursed;
        bool isStudent;
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Denied,
        Closed,
        Executed
    }

    Proposal[] public proposals;
    mapping(address => bool) public isStudent;
    mapping(address => bool) public revoked;
    mapping(address => uint256) public studentMap;

    event StudentRegistered(address indexed student, uint256 indexed imageIPFSHash);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed student);
    event Status(uint256 indexed proposalId, ProposalStatus indexed status);
    event ProposalClosed(uint256 indexed proposalId, ProposalStatus indexed status);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus indexed status);
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);
    event Revoked(address indexed studentAddress, uint256 timestamp);

    modifier validStudent() {
        require(isStudent[msg.sender], "Not a student");
        _;
    }

    modifier notRevoked() {
        require(!revoked[msg.sender], "Revoked");
        _;
    }

    modifier onlyOwnerOrEscrow() {
        require(msg.sender == owner() || msg.sender == address(this), "Not authorized");
        _;
    }

    
    constructor() Ownable(msg.sender) {}
    
    receive() external payable {}

    function registerStudent(string memory _imageIPFSHash, address _student) external payable {
        require(!isStudent[_student], "Student is already registered");
        require(bytes(_imageIPFSHash).length > 0, "Image IPFS hash must not be empty");
        isStudent[_student] = true;

        emit StudentRegistered(_student, 0);
    }

    function createProposal(string memory _description,uint256 _imageIPFSHashTranscript,uint256 _amount) external validStudent payable {
        Proposal memory proposal;
        proposal.proposalId = proposalCount;
        proposal.student = msg.sender;
        proposal.description = _description;
        proposal.status = ProposalStatus.Pending;
        proposal.deadline = block.timestamp + proposalDeadline;
        proposal.imageIPFSHashTranscript = _imageIPFSHashTranscript;
        proposal.amount = _amount;

        proposals.push(proposal);

        emit ProposalCreated(proposalCount, _description, msg.sender);
        proposalCount++;
    }

    function approveProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");
        proposal.status = ProposalStatus.Approved;
        emit Status(_proposalId, ProposalStatus.Approved);
    }

    function closeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(
            proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Pending,
            "Invalid proposal status"
        );
        proposal.status = ProposalStatus.Closed;
        emit ProposalClosed(_proposalId, ProposalStatus.Closed);
    }
    function donate(uint256 _amount, address _student, uint256 _proposalId) external {
    require(_amount > 0, "Amount must be greater than zero");
    require(isStudent[_student], "Recipient is not a registered student");

    // Assuming USDT has 18 decimals, adjust the amount to match the token decimals
    uint256 usdtAmount = _amount * 10**18;

    // Transfer USDT tokens from the sender to this contract
    require(_usdtToken.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

    // Update student's balance
    studentMap[_student] += _amount;

    emit Donation(msg.sender, _amount, block.timestamp);

    // Check if the student's balance is sufficient for disbursement
    if (studentMap[_student] >= proposals[_proposalId].amount) {
        // Disburse funds to the student
        require(_usdtToken.transfer(_student, studentMap[_student]), "USDT transfer failed");
        emit Donation(_student, studentMap[_student], block.timestamp);

        // Reset student's balance
        studentMap[_student] = 0;
    }
}

    function withdraw(uint256 _amount) external onlyOwnerOrEscrow {
        require(_amount > 0, "Amount must be greater than zero");
        require(_usdtToken.balanceOf(address(this)) >= _amount, "Insufficient balance");

        _usdtToken.transfer(owner(), _amount);
    }

    function disburseFund(uint256 _proposalId) external nonReentrant onlyOwner {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        require(proposals[_proposalId].status == ProposalStatus.Approved, "Proposal not approved");
        require(!proposals[_proposalId].disbursed, "Loan already disbursed");

        proposals[_proposalId].disbursed = true;
        require(_usdtToken.balanceOf(address(this)) >= proposals[_proposalId].amount, "Insufficient contract balance");
        _usdtToken.transfer(proposals[_proposalId].student, proposals[_proposalId].amount);
        emit Donation(proposals[_proposalId].student, proposals[_proposalId].amount, block.timestamp);
    }

    function changeProposalState(uint256 _proposalId, bool _proposalState) external onlyOwner {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal status not pending");

        if (_proposalState) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Denied;
        }

        emit Status(_proposalId, proposal.status);
    }

    function revokeStudent(address _studentId) external onlyOwner {
        require(isStudent[_studentId], "Not a student");
        isStudent[_studentId] = false;

        emit Revoked(_studentId, block.timestamp);
    }

    function updateProposalDeadline(uint256 _proposalDeadline) external onlyOwner {
        proposalDeadline = _proposalDeadline;
    }

    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        return proposals[_proposalId];
    }

    function getProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        return proposals[_proposalId].status;
    }

    function getProposalsCount() external view returns (uint256) {
        return proposals.length;
    }

    function toggleRevokedStatus(address _studentAddress) external onlyOwner {
        revoked[_studentAddress] = !revoked[_studentAddress];
        emit Revoked(_studentAddress, block.timestamp);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function rewardNFT(address _recipient, uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        //_nftContract.mint(_recipient, _tokenId);
        //_nftContract.setTokenURI(_tokenId, _tokenURI);
    }
}
