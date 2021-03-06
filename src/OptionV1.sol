// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

/// @title Ethereum The Merge Option Contract V1
/// @author 0xbakuchi
/// @notice
/// bet on whether The Merge will happen in the specified future block number.
//  Winners will receive a payout proportional to their balance of token.
/// @dev
/// According to EIP-4399,
/// the EIP allow for smart contracts to determine whether the upgrade to the PoS has already happened.
/// A value of the DIFFICULTY opcode greater than 2**64 indicates that the transaction is being executed in the PoS block.

contract Token is ERC20 {
    address internal immutable controller;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {
        controller = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == controller, "!minter");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        require(msg.sender == controller, "!burner");
        _burn(to, amount);
    }
}

/// @author 0xbakuchi
contract OptionV1 {
    uint256 public immutable pauseMintingBlockNumber;
    uint256 public immutable settlementBlockNumber;
    uint256 public immutable chainId;

    Token public immutable mergeToken;

    Token public immutable notMergeToken;

    Token public winToken;

    uint256 public totalDepositedEth;

    uint256 public totalSupplyAtSettlementTime;

    constructor(uint256 _settlementBlockNumber, uint256 _pauseMintingBlockNumber) {
        settlementBlockNumber = _settlementBlockNumber;
        pauseMintingBlockNumber = _pauseMintingBlockNumber;
        chainId = block.chainid;

        mergeToken = new Token("Ethereum Merge Token", "ETH_MERGE_TOKEN");
        notMergeToken = new Token("Ethereum Not Merge Token", "ETH_NOT_MERGE_TOKEN");
    }

    function betOnTheMerge() external payable {
        require(block.number < pauseMintingBlockNumber, "pause-minting");
        totalDepositedEth += msg.value;
        mergeToken.mint(msg.sender, msg.value);
    }

    function betOnTheNotMerge() external payable {
        require(block.number < pauseMintingBlockNumber, "pause-minting");
        totalDepositedEth += msg.value;
        notMergeToken.mint(msg.sender, msg.value);
    }

    function redeem() external {
        Token _winToken = winToken;
        require(address(_winToken) != address(0), "!settled");

        uint256 bal = _winToken.balanceOf(msg.sender);
        uint256 payout = (totalDepositedEth * bal) / totalSupplyAtSettlementTime;

        _winToken.burn(msg.sender, bal);
        SafeTransferLib.safeTransferETH(msg.sender, payout);
    }

    function settle() external {
        require(address(winToken) == address(0), "settled");
        //  after the specified block height.
        require(block.number >= settlementBlockNumber, "before-maturity");

        // This contract is valid on the original chain if chiain split happens
        // require(chainId == block.chainid, "chain-split");

        /// A value of the DIFFICULTY opcode greater than 2**64 indicates that the transaction is being executed in the PoS block.
        Token _winToken = block.difficulty > 2**64 ? mergeToken : notMergeToken;

        winToken = _winToken;
        totalSupplyAtSettlementTime = _winToken.totalSupply();
    }
}
