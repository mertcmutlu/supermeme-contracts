pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRefundableBondingCurve.sol";
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
        addresses = generateMultipleAddresses(5);

        //base mainnet router address 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        //base sepolia router address 0x6682375ebC1dF04676c0c5050934272368e6e883

        uint256 createTokenRevenue = 0.00001 ether;
        router = IUniswapV2Router02(
            address(0x6682375ebC1dF04676c0c5050934272368e6e883)
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
            0,
            owner,
            address(0x123),
            0,
            3 days
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
        uint256 nextLockTime = lockingCurve.calculateNextLockTime();
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        uint256 lockTime = lockingCurve.lockTime(addr1);
        assertEq(lockTime, nextLockTime);
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
            uint256 nextLockTime = lockingCurve.calculateNextLockTime();
            console.log("block timestamp", block.timestamp);
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            console.log("block timestamp", block.timestamp);
            console.log("lockTime", lockTime);
            console.log("nextLockTime", nextLockTime);
            assertEq(lockTime, nextLockTime);
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

    function testBuyChecksPassTime() public {
        //loop throuugh 5 users and buy and pass 1 day for each
        for (uint256 i = 0; i < 5; i++) {
            console.log("user number", i);
            vm.startPrank(addresses[i]);
            uint256 amount = 10000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
            console.log("enters next");
            uint256 nextLockTime = lockingCurve.calculateNextLockTime();
            console.log("exits next");
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            console.log("user", i, "bought tokens");
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            console.log("lockTime", lockTime);
            assertEq(lockTime, nextLockTime);
            uint256 initLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 scaledSupply = lockingCurve.scaledSupply();
            uint256 totalSupply = lockingCurve.MAX_SALE_SUPPLY();
            //log the curves progression please

            uint256 curveProgression = (scaledSupply * 100) / totalSupply;
            vm.warp(block.timestamp + 1 days);
            console.log("one day passes", block.timestamp);
            console.log("lock time underflow", lockTime);
            console.log("block timestamp", block.timestamp);
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            console.log(
                "remainingLockTime",
                secondsToHumanReadable(remainingLockTime)
            );
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
        uint256 nextLockTime = lockingCurve.calculateNextLockTime();
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        for (uint256 i = 0; i < 5; i++) {
            uint256 newTimeStamp = 1 days * i;
            vm.warp(newTimeStamp);
            console.log("one day passes", block.timestamp);
            uint256 lockTime = lockingCurve.lockTime(addr1);
            uint256 remainingLockTime = (lockTime < block.timestamp)
                ? 0
                : lockTime - block.timestamp;
            uint256 remaininLockTimeFromContract = lockingCurve
                .checkRemainingLockTime(addr1);
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
            uint256 nextLockTime = lockingCurve.calculateNextLockTime();
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
            assertEq(lockTime, nextLockTime);
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
            uint256 remaininLockTimeFromContract = lockingCurve
                .checkRemainingLockTime(addresses[i]);
            assertEq(remainingLockTime, remaininLockTimeFromContract);
            //log the remaining lock time for all users
            for (uint256 j = 0; j < 5; j++) {
                lockTime = lockingCurve.lockTime(addresses[j]);
                remainingLockTime = (lockTime < block.timestamp)
                    ? 0
                    : lockTime - block.timestamp;
                console.log(
                    "user",
                    j,
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
               uint256 nextLockTime = lockingCurve.calculateNextLockTime();
        uint256 totalCostWithSlippage = totalCost + slippage;
        lockingCurve.buyTokens{value: totalCostWithSlippage}(
            amount,
            100,
            totalCost
        );
        assertEq(lockingCurve.balanceOf(addr1), amount * 10 ** 18);

        uint256 lockTime = lockingCurve.lockTime(addr1);
        assertEq(lockTime, nextLockTime);
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
        lockingCurve.sellTokens(amount / 2, 100);
        assertEq(lockingCurve.balanceOf(addr1), (amount / 2) * 10 ** 18);
        vm.expectRevert();
        lockingCurve.transfer(addr2, amount);
        vm.expectRevert();
        lockingCurve.transfer(address(lockingCurve), (amount / 2) * 10 ** 18);
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
                   uint256 nextLockTime = lockingCurve.calculateNextLockTime();
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(lockingCurve.balanceOf(addresses[i]), amount * 10 ** 18);

            console.log("user", i, "bought tokens");
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            assertEq(lockTime, nextLockTime);
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
            uint256 remaininLockTimeFromContract = lockingCurve
                .checkRemainingLockTime(addresses[i]);
            console.log("before asser");
            assertEq(remainingLockTime, remaininLockTimeFromContract);
            //log the remaining lock time for all users
            for (uint256 j = 0; j < 5; j++) {
                lockTime = lockingCurve.lockTime(addresses[j]);
                remainingLockTime = (lockTime < block.timestamp)
                    ? 0
                    : lockTime - block.timestamp;
                console.log(
                    "user",
                    j,
                    "remainingLockTime",
                    secondsToHumanReadable(remainingLockTime)
                );
            }
        }
        vm.warp(block.timestamp + 1 days);
        for (uint256 j = 0; j < 5; j++) {
            uint256 lockTime = lockingCurve.checkRemainingLockTime(
                addresses[j]
            );
            console.log(
                "user",
                j,
                "remainingLockTime",
                secondsToHumanReadable(lockTime)
            );
        }
    }

    function testCheckLocksAtDexStage() public {
        //buy with 5 users 2 hours apart each
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(addresses[i]);
            uint256 amount = 150000000;
            uint256 cost = lockingCurve.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            uint256 slippage = totalCost / 100;
            uint256 totalCostWithSlippage = totalCost + slippage;
                   uint256 nextLockTime = lockingCurve.calculateNextLockTime();
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(lockingCurve.balanceOf(addresses[i]), amount * 10 ** 18);
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            assertEq(lockTime, nextLockTime);
            uint256 contractLockRemaining = lockingCurve.checkRemainingLockTime(
                addresses[i]
            );
            vm.warp(block.timestamp + 2 hours);
            console.log("curve status", lockingCurve.scaledSupply());
            vm.stopPrank();
        }
        for (uint256 j = 0; j < 5; j++) {
            vm.startPrank(addresses[j]);
            console.log("user", j, "voting to send to dex");
            lockingCurve.sendToDex();
            vm.stopPrank();
        }
        //check if the pool exists
        address[] memory path = new address[](2);
        path[0] = address(lockingCurve);
        path[1] = router.WETH();

        uint256[] memory amounts = router.getAmountsOut(10000000 ether, path);
        console.log("amounts", amounts[0]);
        console.log("amounts", amounts[1]);
        //address 1 tries to sell tokens in dex
        vm.startPrank(addresses[0]);
        lockingCurve.approve(address(router), 10000000 ether);
        vm.expectRevert();
        router.swapExactTokensForETH(
            10000000 ether,
            0,
            path,
            addresses[0],
            block.timestamp + 10 minutes
        );
        vm.warp(block.timestamp + 10 days);
        console.log(
            "remainingLockTime",
            lockingCurve.checkRemainingLockTime(addresses[0])
        );
        console.log("balance of user 1", lockingCurve.balanceOf(addresses[0]));
        console.log("dex stage", lockingCurve.dexStage());
        lockingCurve.approve(address(router), 10000000 ether);
        amounts = router.swapExactTokensForETH(
            10000000 ether,
            10000 gwei,
            path,
            addresses[0],
            block.timestamp + 10 minutes + 10 days
        );
        console.log("amounts", amounts[0]);
        console.log("amounts", amounts[1]);
    }

    function testSendToDexCase1() public {
        //buy with 5 users 2 hours apart each
        uint256 amount = 150000000;
        uint256 cost = lockingCurve.calculateCost(amount);
        uint256 tax = cost / 100;
        uint256 totalCost = cost + tax;
        uint256 slippage = totalCost / 100;
        uint256 totalCostWithSlippage = totalCost + slippage;
        for (uint256 i = 0; i < 5; i++) {
            amount = 150000000;
            cost = lockingCurve.calculateCost(amount);
            tax = cost / 100;
            totalCost = cost + tax;
            slippage = totalCost / 100;
            totalCostWithSlippage = totalCost + slippage;
                   uint256 nextLockTime = lockingCurve.calculateNextLockTime();
            vm.startPrank(addresses[i]);

            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            assertEq(lockingCurve.balanceOf(addresses[i]), amount * 10 ** 18);
            uint256 lockTime = lockingCurve.lockTime(addresses[i]);
            assertEq(lockTime, nextLockTime);
            uint256 contractLockRemaining = lockingCurve.checkRemainingLockTime(
                addresses[i]
            );
            vm.warp(block.timestamp + 2 hours);
            console.log("curve status", lockingCurve.scaledSupply());
            vm.stopPrank();
        }

        //user 1 and 2 votes to send to dex
        for (uint256 j = 0; j < 2; j++) {
            vm.startPrank(addresses[j]);
            console.log("user", j, "voting to send to dex");
            lockingCurve.sendToDex();
            vm.stopPrank();
        }
        assert(lockingCurve.dexStage() == false);
        assert(lockingCurve.scaledBondingCurveCompleted() == true);

        vm.warp(block.timestamp + 10 days);

        //user 1 and 2 sell their tokens
        for (uint256 j = 0; j < 2; j++) {
            vm.startPrank(addresses[j]);
            lockingCurve.sellTokens(amount, 0);
            vm.stopPrank();
        }

        assert(lockingCurve.dexStage() == false);
        assert(lockingCurve.bondingCurveCompleted() == false);
        assert(lockingCurve.scaledBondingCurveCompleted() == false);

        //user 3 votes to send to dex
        vm.startPrank(addresses[2]);
        vm.expectRevert();
        lockingCurve.sendToDex();

        //user 1 and 2 rebuy
        for (uint256 j = 0; j < 2; j++) {
            vm.startPrank(addresses[j]);
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
            assertEq(lockingCurve.balanceOf(addresses[j]), amount * 10 ** 18);
            vm.stopPrank();
        }

        assertEq(lockingCurve.scaledBondingCurveCompleted(), true);

        //check if users received their eth rewards
        uint256[] memory eth_amounts = new uint256[](5);
        for (uint256 j = 0; j < 5; j++) {
            eth_amounts[j] = address(addresses[j]).balance;
        }

        //all users vote to send to dex
        for (uint256 j = 0; j < 5; j++) {
            vm.startPrank(addresses[j]);
            lockingCurve.sendToDex();
            vm.stopPrank();
        }

        for (uint256 j = 0; j < 5; j++) {
            assertGt(address(addresses[j]).balance, eth_amounts[j]);
        }
        assertEq(lockingCurve.dexStage(), true);
        assertEq(lockingCurve.bondingCurveCompleted(), false);

        vm.startPrank(addresses[0]);
        address[] memory path = new address[](2);
        path[0] = address(lockingCurve);
        path[1] = router.WETH();
        uint256[] memory amounts = router.getAmountsOut(10000000 ether, path);

        lockingCurve.approve(address(router), 10000000 ether);
        amounts = router.swapExactTokensForETH(
            10000000 ether,
            10000 gwei,
            path,
            addresses[0],
            block.timestamp + 10 minutes
        );
        console.log("amounts", amounts[0]);
        console.log("amounts", amounts[1]);
        vm.stopPrank();

        //check if the users can sellTokens to the locking curve
        for (uint256 j = 0; j < 5; j++) {
            vm.startPrank(addresses[j]);
            vm.expectRevert();
            lockingCurve.sellTokens(amount, 0);
            vm.stopPrank();
        }

        assertEq(lockingCurve.dexStage(), true);

        //check if the users can buy tokens from the locking curve
        for (uint256 j = 0; j < 5; j++) {
            vm.startPrank(addresses[j]);
            amount = 150000000;
            cost = lockingCurve.calculateCost(amount);
            tax = cost / 100;
            totalCost = cost + tax;
            slippage = totalCost / 100;
            totalCostWithSlippage = totalCost + slippage;
            vm.expectRevert();
            lockingCurve.buyTokens{value: totalCostWithSlippage}(
                amount,
                100,
                totalCost
            );
            vm.stopPrank();
        }
    }

}
