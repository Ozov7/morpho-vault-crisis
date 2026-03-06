// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockMorphoVault {
    function pauseVault() external;
}

contract MorphoVaultCrisisResponse {

    address public owner;
    address public mockVault;

    mapping(address => bool) public authorizedOperators;

    event CrisisDetected(
        uint256 triggeredVectors,
        uint256 utilization,
        uint256 timestamp
    );

    event VaultPaused(address indexed vault, uint256 timestamp);

    modifier onlyOperator() {
        require(authorizedOperators[msg.sender], "not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _mockVault) {
        owner = msg.sender;
        mockVault = _mockVault;
        authorizedOperators[msg.sender] = true;
    }

    function setOperator(address operator, bool status) external onlyOwner {
        authorizedOperators[operator] = status;
    }

    function respond(
        uint256 triggeredVectors,
        uint256 utilization
    ) external onlyOperator {
        emit CrisisDetected(triggeredVectors, utilization, block.timestamp);

        if (mockVault != address(0)) {
            IMockMorphoVault(mockVault).pauseVault();
            emit VaultPaused(mockVault, block.timestamp);
        }
    }
}
