// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// ─── Mock Morpho Vault ───────────────────────────────────────────────────────

contract MockMorphoVault {

    address public owner;
    bool public paused;

    uint256 public totalAssets;
    uint256 public totalBorrows;
    uint256 public pendingWithdrawals;
    uint256 public currentPrice;
    uint256 public lastPrice;

    event VaultPaused(uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Safe default state — no crisis
        totalAssets       = 1_000_000e18;
        totalBorrows      = 700_000e18;  // 70% utilization (safe)
        pendingWithdrawals = 50_000e18;  // 5% withdrawal queue (safe)
        currentPrice      = 2000e8;      // $2000
        lastPrice         = 2000e8;      // no deviation
    }

    function getVaultData() external view returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return (
            totalAssets,
            totalBorrows,
            pendingWithdrawals,
            currentPrice,
            lastPrice
        );
    }

    // Simulate crisis — call this to trigger the trap
    function simulateCrisis() external onlyOwner {
        totalBorrows       = 950_000e18;  // 95% utilization ✓ Vector 1
        pendingWithdrawals = 150_000e18;  // 15% withdrawal  ✓ Vector 2
        currentPrice       = 1850e8;      // 7.5% price drop ✓ Vector 3
    }

    // Reset to safe state
    function resetVault() external onlyOwner {
        totalBorrows       = 700_000e18;
        pendingWithdrawals = 50_000e18;
        currentPrice       = 2000e8;
        lastPrice          = 2000e8;
        paused             = false;
    }

    // Called by Response contract during crisis
    function pauseVault() external {
        paused = true;
        emit VaultPaused(block.timestamp);
    }

    // Manual state setters for testing
    function setVaultData(
        uint256 _totalAssets,
        uint256 _totalBorrows,
        uint256 _pendingWithdrawals,
        uint256 _currentPrice,
        uint256 _lastPrice
    ) external onlyOwner {
        totalAssets        = _totalAssets;
        totalBorrows       = _totalBorrows;
        pendingWithdrawals = _pendingWithdrawals;
        currentPrice       = _currentPrice;
        lastPrice          = _lastPrice;
    }
}

// ─── Response Contract ───────────────────────────────────────────────────────

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

// ─── Deploy Script ───────────────────────────────────────────────────────────

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy MockMorphoVault
        MockMorphoVault mockVault = new MockMorphoVault();
        console.log("MockMorphoVault deployed at:", address(mockVault));

        // 2. Deploy Response contract, wired to MockVault
        MorphoVaultCrisisResponse response = new MorphoVaultCrisisResponse(
            address(mockVault)
        );
        console.log("MorphoVaultCrisisResponse deployed at:", address(response));

        vm.stopBroadcast();
    }
}
