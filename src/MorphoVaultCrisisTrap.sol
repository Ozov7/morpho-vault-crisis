// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "drosera-contracts/interfaces/ITrap.sol";

interface IMockMorphoVault {
    function getVaultData() external view returns (
        uint256 totalAssets,
        uint256 totalBorrows,
        uint256 pendingWithdrawals,
        uint256 currentPrice,
        uint256 lastPrice
    );
}

contract MorphoVaultCrisisTrap is ITrap {

    // ⚠️ Replace with MockMorphoVault address after deployment
    address public constant MOCK_VAULT = 0x2F29A61d60e24764335B0E28459B4D56fC637B68;

    uint256 public constant UTILIZATION_THRESHOLD    = 90; // 90%
    uint256 public constant WITHDRAWAL_THRESHOLD     = 10; // 10% of assets
    uint256 public constant PRICE_DEVIATION_THRESHOLD = 5; // 5%

    function collect() external view override returns (bytes memory) {
        (
            uint256 totalAssets,
            uint256 totalBorrows,
            uint256 pendingWithdrawals,
            uint256 currentPrice,
            uint256 lastPrice
        ) = IMockMorphoVault(MOCK_VAULT).getVaultData();

        return abi.encode(
            totalAssets,
            totalBorrows,
            pendingWithdrawals,
            currentPrice,
            lastPrice
        );
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        // RULE 3: Data length guard
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        (
            uint256 totalAssets,
            uint256 totalBorrows,
            uint256 pendingWithdrawals,
            uint256 currentPrice,
            uint256 lastPrice
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256, uint256));

        // RULE 6: Math safety — guard zero denominators
        if (totalAssets == 0) return (false, bytes(""));
        if (lastPrice == 0)   return (false, bytes(""));

        uint256 triggeredVectors = 0;

        // Vector 1: Vault utilization > 90%
        uint256 utilization = (totalBorrows * 100) / totalAssets;
        if (utilization > UTILIZATION_THRESHOLD) {
            triggeredVectors += 1;
        }

        // Vector 2: Withdrawal queue > 10% of total assets
        uint256 withdrawalRatio = (pendingWithdrawals * 100) / totalAssets;
        if (withdrawalRatio > WITHDRAWAL_THRESHOLD) {
            triggeredVectors += 2;
        }

        // Vector 3: Oracle price deviation > 5% from last sample
        uint256 priceDelta;
        if (currentPrice >= lastPrice) {
            priceDelta = currentPrice - lastPrice;
        } else {
            priceDelta = lastPrice - currentPrice;
        }
        uint256 priceDeviation = (priceDelta * 100) / lastPrice;
        if (priceDeviation > PRICE_DEVIATION_THRESHOLD) {
            triggeredVectors += 4;
        }

        if (triggeredVectors == 0) return (false, bytes(""));

        return (true, abi.encode(triggeredVectors, utilization));
    }
}
