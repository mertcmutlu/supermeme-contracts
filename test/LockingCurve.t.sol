pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRefundableBondingCurve.sol";
import "../src/SuperMemeFactory.sol";
import "../src/SuperMemeLockingCurve.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
//import uniswap pair
import {IUniswapV2Pair} from "../src/Interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";

contract LockingCurve is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;
    IUniswapV2Pair public pair;
    IUniswapFactory public unifactory;
    IUniswapV2Router02 public router;

    SuperMemeLockingCurve public lockingCurve;

    uint256 public createTokenRevenue = 0.00001 ether;
    address private constant BASE_ADDRESS =
        0x1234567890123456789012345678901234567890; // Example base address

    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);
    address public addr4 = address(0x131415);
    address public addr5 = address(0x161718);
    address public addr6 = address(0x192021);
    address public addr7 = address(0x222324);

    address[] public addresses;

    function generateAddress(uint256 index) public pure returns (address) {
        // Generate an address based on a base address and an index
        // This is just a simple example and does not produce unique private keys
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(BASE_ADDRESS, index)))
                )
            );
    }

    function generateMultipleAddresses(
        uint256 count
    ) public returns (address[] memory) {
        require(count > 0, "Count must be greater than zero");

        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = generateAddress(i);
            vm.deal(addresses[i], 1000 ether);
        }

        return addresses;
    }

    function setUp() public {
        addresses = generateMultipleAddresses(80);

        uint256 createTokenRevenue = 0.00001 ether;
        router = IUniswapV2Router02(
            address(0x5633464856F58Dfa9a358AfAf49841FEE990e30b)
        );
        address fakeContract = address(0x12123123);
        unifactory = IUniswapFactory(
            address(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6)
        );
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);
        vm.deal(addr4, 1000 ether);
        vm.deal(addr5, 1000 ether);
        vm.deal(addr6, 1000 ether);
        vm.deal(addr7, 1000 ether);

        lockingCurve = new SuperMemeLockingCurve(
            "SuperMeme",
            "MEME",
            false,
            0,
            owner,
            address(0x123),
            0,
            0
        );

        vm.stopPrank();
    }
    function secondsToHumanReadable(
        uint256 totalSeconds
    ) public pure returns (string memory) {

        if (totalSeconds == 0) {
            return "0 seconds";
        }

        uint256 secondsInMinute = 60;
        uint256 secondsInHour = 3600;
        uint256 secondsInDay = 86400;
        uint256 days1 = totalSeconds / secondsInDay;
        uint256 hours1 = (totalSeconds % secondsInDay) / secondsInHour;
        uint256 minutes1 = (totalSeconds % secondsInHour) / secondsInMinute;
        uint256 seconds1 = totalSeconds % secondsInMinute;
        //return 0 as zero as well

        return
            string(
                abi.encodePacked(
                    days1 > 0
                        ? string(abi.encodePacked(uint2str(days1), " days, "))
                        : "",
                    hours1 > 0
                        ? string(abi.encodePacked(uint2str(hours1), " hours, "))
                        : "",
                    minutes1 > 0
                        ? string(
                            abi.encodePacked(uint2str(minutes1), " minutes, ")
                        )
                        : "",
                    seconds1 > 0
                        ? string(
                            abi.encodePacked(uint2str(seconds1), " seconds")
                        )
                        : ""
                    
                )
            );
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        return string(bstr);
    }

    function testDeploy() public {
        assertEq(lockingCurve.revenueCollector(), address(0x123));
    }

    function testBuyCheckLocks() public {
        vm.startPrank(addr1);
        uint256 amount = 10000000;
        uint256 cost = lockingCurve.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        uint256 lockTime = lockingCurve.calculateLockingDuration(addr1);
        uint256 pureLockTime = lockTime - block.timestamp;
        console.log("lockTime", lockTime);
        console.log("pureLockTime", secondsToHumanReadable(pureLockTime));
        vm.stopPrank();
    }

    function testBuyCheckLocksMultiple() public {
        //loop throuugh addresses
        for (uint256 i = 0; i < addresses.length; i++) {
            console.log("user numner", i);
            vm.startPrank(addresses[i]);
            uint256 amount = 10000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            uint256 initLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 scaledSupply = lockingCurve.scaledSupply();
            uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
            //log the curves progression please
            uint256 curveProgression = (scaledSupply * 100) / totalSupply;
            console.log("curveProgression", curveProgression);
            console.log("pureLockTime", secondsToHumanReadable(initLockTime));
            console.log("token bought amount", amount);
            console.log("     ");
            vm.stopPrank();
        }
    }

    function testBuyChecksPassTime5() public {
        //loop throuugh 5 users and buy and pass 1 day for each
        for (uint256 i = 0; i < 5; i++) {
            console.log("user numner", i);
            vm.startPrank(addresses[i]);
            uint256 amount = 10000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            uint256 initLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 scaledSupply = lockingCurve.scaledSupply();
            uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
            //log the curves progression please

            uint256 curveProgression = (scaledSupply * 100) / totalSupply;
            vm.warp(block.timestamp + 1 days);
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;

            vm.stopPrank();
        }
    }

    function testOneUserBuysCheckDecreasingLockTime() public {
        vm.startPrank(addr1);
        uint256 amount = 10000000;
        uint256 cost = lockingCurve.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        for (uint256 i = 0; i < 10; i++) {
            uint256 newTimeStamp = 1 days * i;
            vm.warp(newTimeStamp);
            console.log("one day passes", block.timestamp);
            uint256 lockTime = lockingCurve.lockTime(addr1);
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 remaininLockTimeFromContract = lockingCurve.checkRemainingLockTime(addr1);
            assertEq(remainingLockTime, remaininLockTimeFromContract);
            console.log(
                "remainingLockTime",
                secondsToHumanReadable(remainingLockTime)
            );
        }
        vm.stopPrank();
    }

       function testMultipleUserBuysCheckDecreasingLockTime() public {
        //loop throuugh 5 users and buy and pass 1 day for each
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(addresses[i]);
            uint256 amount = 50000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(lockingCurve.balanceOf(addresses[i]), amount * 10 ** 18);
            console.log("user", i, "bought tokens");
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            uint256 initLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 scaledSupply = lockingCurve.scaledSupply();
            uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
            //log the curves progression please

            uint256 curveProgression = (scaledSupply * 100) / totalSupply;
            
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 remaininLockTimeFromContract = lockingCurve.checkRemainingLockTime(addresses[i]);
            assertEq(remainingLockTime, remaininLockTimeFromContract);
            //log the remaining lock time for all users
            for (uint256 j = 0; j < 5; j++) {
                lockTime = lockingCurve.lockTime(addresses[j]);
                remainingLockTime = (lockTime < block.timestamp)
                    ? 0
                    : lockTime - block.timestamp;
                console.log(
                    "user", j,
                    "remainingLockTime",
                    secondsToHumanReadable(remainingLockTime)
                );
            }
            vm.warp(block.timestamp + 8 hours);
            console.log("8 hours passes", block.timestamp);
            vm.stopPrank();
        }
}

    function testOneUserBuysTransfer() public {
        vm.startPrank(addr1);
        uint256 amount = 10000000;
        uint256 cost = lockingCurve.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        assertEq(lockingCurve.balanceOf(addr1), amount * 10 ** 18);
        uint256 lockTime = lockingCurve.lockTime(addr1);
        uint256 initLockTime = (lockTime < block.timestamp)
            ? 0
            : lockTime - block.timestamp;
        uint256 scaledSupply = lockingCurve.scaledSupply();
        uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
        vm.expectRevert();
        lockingCurve.transfer(addr2, amount);
        vm.expectRevert();
        lockingCurve.sellTokens(amount, 100);
        vm.expectRevert();
        lockingCurve.transferFrom(addr1, addr2, amount);
        vm.warp(block.timestamp + 4 days);
        console.log(lockingCurve.balanceOf(addr1));
        lockingCurve.sellTokens(amount/2, 100);
        assertEq(lockingCurve.balanceOf(addr1), amount/2 * 10 ** 18);
        vm.expectRevert();
        lockingCurve.transfer(addr2, amount);
        vm.expectRevert();
        lockingCurve.transfer(address(lockingCurve), amount/2 * 10 ** 18);
        vm.stopPrank();
    }

    function testBuyMultipleUsersSellAfterLockExpiry() public {
        //loop throuugh 5 users and buy and pass 1 day for each
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(addresses[i]);
            uint256 amount = 50000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(lockingCurve.balanceOf(addresses[i]), amount * 10 ** 18);
            console.log("user", i, "bought tokens");
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            uint256 initLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 scaledSupply = lockingCurve.scaledSupply();
            uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
            //log the curves progression please

            uint256 curveProgression = (scaledSupply * 100) / totalSupply;
            
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 remaininLockTimeFromContract = lockingCurve.checkRemainingLockTime(addresses[i]);
            console.log("before asser");
            assertEq(remainingLockTime, remaininLockTimeFromContract);
            //log the remaining lock time for all users
            for (uint256 j = 0; j < 5; j++) {
                lockTime = lockingCurve.lockTime(addresses[j]);
                remainingLockTime = (lockTime < block.timestamp)
                    ? 0
                    : lockTime - block.timestamp;
                console.log(
                    "user", j,
                    "remainingLockTime",
                    secondsToHumanReadable(remainingLockTime)
                );
            }
        }
        vm.warp(block.timestamp + 1 days);
            for (uint256 j = 0; j < 5; j++) {
                uint256 lockTime = lockingCurve.checkRemainingLockTime(addresses[j]);
                console.log(
                    "user", j,
                    "remainingLockTime",
                    secondsToHumanReadable(lockTime)
                );
            }

    }
}   