// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IMockMorphoVault {
    function getVaultData() external view returns (
        uint256 totalAssets,
        uint256 totalBorrows,
        uint256 pendingWithdrawals,
        uint256 currentPrice
    );
}

contract MorphoVaultCrisisTrap is ITrap {

    address public constant MOCK_VAULT = 0x5340F06722364576073140591f2F1192510D6fc5;

    uint256 public constant UTILIZATION_THRESHOLD     = 90;
    uint256 public constant WITHDRAWAL_THRESHOLD      = 10;
    uint256 public constant PRICE_DEVIATION_THRESHOLD = 5;
    uint256 public constant MIN_VECTORS_FOR_PAUSE     = 2;

    function collect() external view override returns (bytes memory) {
        (
            uint256 totalAssets,
            uint256 totalBorrows,
            uint256 pendingWithdrawals,
            uint256 currentPrice
        ) = IMockMorphoVault(MOCK_VAULT).getVaultData();

        return abi.encode(
            totalAssets,
            totalBorrows,
            pendingWithdrawals,
            currentPrice
        );
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        // RULE 3: Data length guard — now requires 2 samples
        if (data.length < 2) return (false, bytes(""));
        if (data[0].length == 0 || data[1].length == 0) return (false, bytes(""));

        // Current block sample
        (
            uint256 totalAssets,
            uint256 totalBorrows,
            uint256 pendingWithdrawals,
            uint256 currentPrice
        ) = abi.decode(data[0], (uint256, uint256, uint256, uint256));

        // Previous block sample — native Drosera historical comparison
        (
            ,
            ,
            ,
            uint256 lastPrice
        ) = abi.decode(data[1], (uint256, uint256, uint256, uint256));

        // Math safety
        if (totalAssets == 0) return (false, bytes(""));
        if (lastPrice == 0)   return (false, bytes(""));

        uint256 triggeredVectors = 0;

        // Vector 1: Utilization > 90%
        uint256 utilization = (totalBorrows * 100) / totalAssets;
        if (utilization > UTILIZATION_THRESHOLD) {
            triggeredVectors += 1;
        }

        // Vector 2: Withdrawal queue > 10% of assets
        uint256 withdrawalRatio = (pendingWithdrawals * 100) / totalAssets;
        if (withdrawalRatio > WITHDRAWAL_THRESHOLD) {
            triggeredVectors += 1;
        }

        // Vector 3: Price deviation across blocks using Drosera native sampling
        uint256 priceDelta;
        if (currentPrice >= lastPrice) {
            priceDelta = currentPrice - lastPrice;
        } else {
            priceDelta = lastPrice - currentPrice;
        }
        uint256 priceDeviation = (priceDelta * 100) / lastPrice;
        if (priceDeviation > PRICE_DEVIATION_THRESHOLD) {
            triggeredVectors += 1;
        }

        // Require minimum 2-of-3 vectors before responding
        if (triggeredVectors < MIN_VECTORS_FOR_PAUSE) return (false, bytes(""));

        return (true, abi.encode(triggeredVectors, utilization));
    }
}
