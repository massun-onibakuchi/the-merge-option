// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./OptionV1.sol";
import "forge-std/Test.sol";

contract TestOptionV1 is Test {
    OptionV1 internal option;
    Token internal mergeToken;

    Token internal notMergeToken;

    receive() external payable {}

    function setUp() public {
        option = new OptionV1(block.number + 1500, block.number + 100);
        mergeToken = option.mergeToken();
        notMergeToken = option.notMergeToken();
    }

    function testInit() external {
        assertTrue(address(mergeToken) != address(0));
        assertTrue(address(notMergeToken) != address(0));
        assertEq(mergeToken.totalSupply(), 0);
        assertEq(notMergeToken.totalSupply(), 0);
    }

    function testOnlyMinter() external {
        vm.expectRevert(bytes("!minter"));
        mergeToken.mint(address(this), 0);

        vm.expectRevert(bytes("!minter"));
        notMergeToken.mint(address(this), 0);
    }

    function testOnlyBurner() external {
        vm.expectRevert(bytes("!burner"));
        mergeToken.burn(address(this), 0);

        vm.expectRevert(bytes("!burner"));
        notMergeToken.burn(address(this), 0);
    }

    function testBetOnTheMerge() external {
        option.betOnTheMerge{value: 100}();
        assertEq(mergeToken.balanceOf(address(this)), 100);
        assertEq(option.totalDepositedEth(), 100);

        vm.roll(block.number + 200);

        vm.expectRevert(bytes("pause-minting"));
        option.betOnTheMerge{value: 100}();
    }

    function testBetOnTheNotMerge() external {
        option.betOnTheNotMerge{value: 100}();
        assertEq(notMergeToken.balanceOf(address(this)), 100);
        assertEq(option.totalDepositedEth(), 100);

        vm.roll(block.number + 200);

        vm.expectRevert(bytes("pause-minting"));
        option.betOnTheNotMerge{value: 100}();
    }

    function testRedeemValidation() external {
        vm.expectRevert(bytes("!settled"));
        option.redeem();
    }

    function testRedeem() external {
        option.betOnTheMerge{value: 1000}();
        option.betOnTheNotMerge{value: 100}();

        vm.roll(block.number + 1501);
        option.settle(); // Merge doesn't happen
        uint256 totalSupply = option.totalSupplyAtSettlementTime();

        uint256 bal = address(this).balance;
        option.redeem();
        assertEq(address(this).balance - bal, 1100);
        assertEq(notMergeToken.balanceOf(address(this)), 0);
        assertEq(option.totalSupplyAtSettlementTime(), totalSupply);
    }

    function testSettleValidation() external {
        vm.expectRevert(bytes("before-maturity"));
        option.settle();

        vm.roll(block.number + 1501);
        option.settle();

        vm.expectRevert(bytes("settled"));
        option.settle();
    }
}
