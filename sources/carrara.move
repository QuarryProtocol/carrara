/// Liquidity mining rewards distribution program.
/// 
/// This is a port of the original [Quarry Protocol](https://github.com/QuarryProtocol/quarry)
/// to idiomatic Move, with a few changes:
/// 
/// - The Redeemer and Mint Wrapper have been replaced by a `Coin` storing rewards to distribute.
///   - The original Quarry protocol had issues with projects issuing coins that they didn't have.
/// - The Operator has been replaced by a set of capabilities.
///   - The original Operator system helped increase the granularity of access control. However, it is unnecessary indirection, and the capability design pattern works well.
/// 
/// __Note:__ This repo is a work in progress.

module carrara::carrara {}
