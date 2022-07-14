# Carrara: Aptos Liquidity Mining

A port of Quarry Protocol to idiomatic Move, with a few changes:

- The Redeemer and Mint Wrapper have been replaced by a `Coin` storing rewards to distribute.
  - The original Quarry protocol had issues with projects issuing coins that they didn't have.
- The Operator has been replaced by a set of capabilities.
  - The original Operator system helped increase the granularity of access control. However, it is unnecessary indirection, and the capability design pattern works well.

**Note:** This repo is a work in progress.

## Installation

To use carrara in your code, add the following to the `[addresses]` section of your `Move.toml`:

```toml
[addresses]
carrara = "0x8f6ce396d6c4b9c7c992f018e94df010ec5c50835d1c83186c023bfa22df638c"
```

## License

Apache-2.0
