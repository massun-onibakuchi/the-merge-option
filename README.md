# The Merge Option

Option contract to bet on whether The Merge will happen within a specified future block number.

[bakuchi's idea](https://twitter.com/0xbakuchi/status/1548565577899188224?s=20&t=gvbAaFbMDyPBq3i-BuwY-Q)

## How it works
1. participants bet ETH on whether the merge will occur before the specified block height. they receives shares based on their wager.
2. they trade those shares on DEX freely.
3. the result of The Merge is judged on the contract based on EIP 4399. [details are here](#post-merge-difficulty-opcodes-changes)
4. after maturity, winners can redeem ETH in proportion to the wager.

## Post-Merge, `DIFFICULTY` opcodes changes

> Additionally, changes proposed by [this EIP](https://eips.ethereum.org/EIPS/eip-4399) allow for smart contracts to determine whether the upgrade to the PoS has already happened. This can be done by analyzing the return value of the DIFFICULTY opcode. A value greater than 2\*\*64 indicates that the transaction is being executed in the PoS block.

> https://blog.ethereum.org/2021/11/29/how-the-merge-impacts-app-layer/
