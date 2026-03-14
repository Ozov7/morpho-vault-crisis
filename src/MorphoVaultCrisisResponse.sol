// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockMorphoVault {
    function pauseVault() external;
}

contract MorphoVaultCrisisResponse {

    address public owner;
    address public mockVault;

    mapping(address => bool) public authorizedOperators;

    event CrisisWarning(
        uint256 triggeredVectors,
        uint256 utilization,
        uint256 timestamp
    );

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

    // Fix 1 & 2: onlyOperator applied to respond()
    // Fix 6: Tiered response — 2 vectors = warning, 3 vectors = full pause
    function respond(
        uint256 triggeredVectors,
        uint256 utilization
    ) external onlyOperator {

        if (triggeredVectors == 2) {
            // Medium signal: emit warning only, no pause
            emit CrisisWarning(triggeredVectors, utilization, block.timestamp);
            return;
        }

        if (triggeredVectors >= 3) {
            // Strong signal: full vault pause
            emit CrisisDetected(triggeredVectors, utilization, block.timestamp);
            if (mockVault != address(0)) {
                IMockMorphoVault(mockVault).pauseVault();
                emit VaultPaused(mockVault, block.timestamp);
            }
        }
    }
}

