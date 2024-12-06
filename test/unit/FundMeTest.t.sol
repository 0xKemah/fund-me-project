// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund(); // send 0 Eth which should cause a revert
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAmountFundedIsUpdatedCorrectly() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunders(0);

        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawingWithASingleFunder() public funded {
        // Arrage
        uint256 initialFundMeBalance = address(fundMe).balance;
        uint256 initialBalanceOfOwner = fundMe.getOwner().balance;

        // Act
        uint256 gasStart = gasleft(); // gasLeft() gives the amount of gas not used in a tx
        vm.txGasPrice(GAS_PRICE); // Specify to anvil to spend gas
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // gasprice is a built in solidity function that returns the current gas price
        console.log(gasUsed);

        // Assert
        uint256 finalFundMeBalance = address(fundMe).balance;
        uint256 finalBalanceOfOwner = fundMe.getOwner().balance;
        assertEq(finalFundMeBalance, 0);
        assertEq(
            (initialBalanceOfOwner + initialFundMeBalance),
            finalBalanceOfOwner
        );
    }

    function testWithdrawingWithMultiFunders() public funded {
        // Arrage
        uint160 numberOfFunders = 20; // We use uint160 here since we are working with address data type in our loop
        uint160 initialIndex = 1;

        for (uint160 i = initialIndex; i < numberOfFunders; i++) {
            // Here hoax is same as using vm.prank and vm.duel together
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 initialBalanceOfOwner = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            initialBalanceOfOwner + initialFundMeBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawingWithMultiFundersCheaper() public funded {
        // Arrage
        uint160 numberOfFunders = 20; // We use uint160 here since we are working with address data type in our loop
        uint160 initialIndex = 1;

        for (uint160 i = initialIndex; i < numberOfFunders; i++) {
            // Here hoax is same as using vm.prank and vm.duel together
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 initialBalanceOfOwner = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            initialBalanceOfOwner + initialFundMeBalance,
            fundMe.getOwner().balance
        );
    }
}
