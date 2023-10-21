// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import {Test, console2} from "forge-std/Test.sol";
import {WETH} from "../src/WETH.sol";


//問題
//1.line 57 - 64 轉帳給 0x0 ，餘額沒有增加？
//2.轉帳 ether 以外的token， 單位可以用 ether ？還是 XXe18 好？
//3.測試數量建議直接寫死？還是相對單位？

contract WETHTest is Test {
    WETH public weth;
    uint beforeBurnAddressWETHBalance;
    uint beforeTestContractWETHBalance;
    uint beforeTestContractETHBalance;
    uint beforeWETHContractETHBalance;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        weth = new WETH();
        deal(address(this), 10 ether);
        deal(address(weth), 10 ether);
        deal(address(weth), address(this), 5 ether);

        beforeTestContractWETHBalance = weth.balanceOf(address(this));
        beforeTestContractETHBalance = address(this).balance;

        beforeWETHContractETHBalance = address(weth).balance;
    }

    fallback() external payable {}

    receive() external payable {}

    function testDeposit() public {
        vm.expectEmit(true, false, false, true, address(weth));
        emit Deposit(address(this), 1 ether);
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), beforeTestContractWETHBalance + 1 ether);
        assertEq(address(weth).balance - beforeWETHContractETHBalance, 1 ether);
    }

    function testWithdraw() public {

        vm.expectEmit(true, false, false, true, address(weth));
        emit Transfer(address(this), address(0), 1 ether);
        emit Withdrawal(address(this), 1 ether);
        weth.withdraw(1 ether);
        assertEq(beforeTestContractWETHBalance - weth.balanceOf(address(this)), 1 ether);
        assertEq(address(this).balance - beforeTestContractETHBalance, 1 ether);

        //---------
        vm.expectRevert(bytes("not enough weth"));
        weth.withdraw(10000 ether);



    }

    function testTransfer() public {
        address BobAddress = makeAddr('Bob');
        deal(address(weth), BobAddress, 10 ether);
        uint beforeBobAddressWETHBalance = weth.balanceOf(address(BobAddress));

        vm.startPrank(BobAddress);

        vm.expectEmit(true, false, false, true, address(weth));
        emit Transfer(BobAddress, address(this), 1 ether);

        weth.transfer(address(this), 1 ether);
        vm.stopPrank();

        assertEq(beforeBobAddressWETHBalance - weth.balanceOf(address(BobAddress)), 1 ether);
        assertEq(weth.balanceOf(address(this)) - beforeTestContractWETHBalance, 1 ether);
    }

    function testApprove() public {

        address BobAddress = makeAddr('Bob');
        deal(address(weth), BobAddress, 10 ether);

        vm.startPrank(BobAddress);

        vm.expectEmit(true, true, false, true, address(weth));
        emit Approval(BobAddress, address(this), 1 ether);

        weth.approve(address(this), 1 ether);
        vm.stopPrank();

        assertEq(weth.allowance(BobAddress, address(this)), 1 ether);
    }

    function testTransferFrom() public {
        //address from, address to, uint256 value
        address BobAddress = makeAddr('Bob');
        deal(address(weth), BobAddress, 10e18);
        vm.startPrank(BobAddress);
        weth.approve(address(this), 5e18);        
        vm.stopPrank();

        vm.expectEmit(true, false, false, true, address(weth));
        emit Transfer(BobAddress, address(this), 1e18);

        assertEq(weth.allowance(BobAddress, address(this)), 5e18);
        weth.transferFrom(BobAddress, address(this), 1e18);
        assertEq(weth.allowance(BobAddress, address(this)), 4e18);

        assertEq(weth.balanceOf(BobAddress), 9e18);
        assertEq(weth.balanceOf(address(this)), 6e18);
    }


}
