// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LoyaltyApp is ERC20 {
    using EnumerableSet for EnumerableSet.UintSet;

    address public owner;
    mapping(address => uint256) public loyaltyPoints;
    mapping(address => uint256) public votingPower;
    mapping(address => address) public delegatedVotingPower;
    mapping(uint256 => mapping(address => uint256)) public snapshotVotingPower;

    EnumerableSet.UintSet private snapshotIds;

    event LoyaltyPointsEarned(address indexed user, uint256 points);
    event LoyaltyPointsRedeemed(address indexed user, uint256 points);
    event Voted(address indexed user, uint256 points);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee, uint256 points);
    event SnapshotAdded(uint256 snapshotId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() ERC20("LoyaltyAppToken", "LAT") {
        owner = msg.sender;
    }

    function earnLoyaltyPoints(uint256 points) external {
        _mint(msg.sender, points);
        loyaltyPoints[msg.sender] += points;
        emit LoyaltyPointsEarned(msg.sender, points);
    }

    function redeemLoyaltyPoints(uint256 points) external {
        require(loyaltyPoints[msg.sender] >= points, "Insufficient loyalty points");
        _burn(msg.sender, points);
        loyaltyPoints[msg.sender] -= points;
        emit LoyaltyPointsRedeemed(msg.sender, points);
    }

    function vote(uint256 points) external {
        require(loyaltyPoints[msg.sender] >= points, "Insufficient loyalty points");
        votingPower[msg.sender] += points;
        loyaltyPoints[msg.sender] -= points;
        emit Voted(msg.sender, points);
    }

    function delegateVotingPower(address delegatee) external {
        require(delegatee != address(0), "Invalid delegatee address");
        require(msg.sender != delegatee, "Cannot delegate to yourself");
        require(loyaltyPoints[msg.sender] >= votingPower[msg.sender], "Insufficient voting power to delegate");

        delegatedVotingPower[msg.sender] = delegatee;
        emit VotingPowerDelegated(msg.sender, delegatee, votingPower[msg.sender]);
    }

    function snapshotVotingPowerForBlock(uint256 snapshotId) external {
        require(!snapshotIds.contains(snapshotId), "Snapshot ID already exists");
        snapshotIds.add(snapshotId);
        for (uint256 i = 0; i < snapshotIds.length(); i++) {
            snapshotVotingPower[snapshotId][msg.sender] = votingPower[msg.sender];
        }
        emit SnapshotAdded(snapshotId);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        loyaltyPoints[msg.sender] -= amount;
        loyaltyPoints[recipient] += amount;
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        loyaltyPoints[sender] -= amount;
        loyaltyPoints[recipient] += amount;
        return super.transferFrom(sender, recipient, amount);
    }
}