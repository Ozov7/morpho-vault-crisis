## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Morpho Vault Crisis Trap

A 3-vector Drosera trap monitoring a simulated Morpho Blue vault for crisis conditions on Hoodi Testnet.

## What It Monitors

| Vector | Condition | Threshold |
|--------|-----------|-----------|
| 1 | Vault utilization | > 90% |
| 2 | Withdrawal queue | > 10% of assets |
| 3 | Oracle price deviation | > 5% from last sample |

## Contracts

| Contract | Address |
|----------|---------|
| MockMorphoVault | `0xF13E05f2002Eae3570203AeA94915Ebc000A688d` |
| MorphoVaultCrisisResponse | `0xacED975dBE084377BDE20de4DCE5224c7166FBE3` |
| Trap | `0x751ecc4c5e06c8aF87f5b4F9a8F937a6EC50D057` |

## How It Works

1. `collect()` reads live vault state from MockMorphoVault
2. `shouldRespond()` evaluates all 3 vectors independently
3. If any vector is triggered, Response contract pauses the vault

## Testing

To simulate a crisis:
```solidity
MockMorphoVault.simulateCrisis()
This sets utilization to 95%, withdrawal queue to 15%, and price drop to 7.5% — triggering all 3 vectors simultaneously.
Network
Network: Hoodi Testnet (Chain ID: 560048)
Block Sample Size: 1
Cooldown: 33 blocks
