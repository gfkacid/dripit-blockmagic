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

Test Token - https://testnet.snowtrace.io/token/0x854381F2ea0c1E55D6823b908b1a028027B92f1E/contract/code?chainId=43113

Test USDC - https://testnet.snowtrace.io/address/0x5425890298aed601595a70AB815c96711a31Bc65

BattleTicket - https://testnet.snowtrace.io/address/0x62db543737e81ccff92f66e47d8a166dbe23765b

Battles - https://testnet.snowtrace.io/address/0x3596AE0a46B67BA819926Ba6f4D3e59BfF659F1A
