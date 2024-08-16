pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRefundableBondingCurve.sol";
import "../src/SuperMemeFactory.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
//import uniswap pair
import {IUniswapV2Pair} from "../src/Interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";

contract BondingCurvePricingTest is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;
    IUniswapV2Pair public pair;
    IUniswapFactory public unifactory;    
    SuperMemeFactory public factory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    uint256 public createTokenRevenue = 0.00001 ether;
    IUniswapV2Router02 public router;
    SuperMemeDegenBondingCurve public testTokenInstanceDegen;
    SuperMemeRefundableBondingCurve public testTokenInstanceRefund;
    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);
    function setUp() public {
        uint256 createTokenRevenue = 0.00001 ether;
        router = IUniswapV2Router02(address(0x5633464856F58Dfa9a358AfAf49841FEE990e30b));
        address fakeContract = address(0x12123123);
        unifactory = IUniswapFactory(address(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6));
        degenbondingcurve = new SuperMemeDegenBondingCurve(
            "SuperMeme",
            "MEME",
            false,
            0,
            owner,
            address(0x123),
            0,
            0
        );
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.startPrank(addr1);
        factory = new SuperMemeFactory();
        //Create a token
        address testToken = factory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            false,
            0,
            address(addr1),
            0,
            0,
            0
        );
        testTokenInstanceDegen = SuperMemeDegenBondingCurve(
                testToken
            );
        console.log("before refundable");
        address testToken2 = factory.createToken{value: createTokenRevenue}(
            "SuperMeme2",
            "MEM",
            false,
            0,
            address(addr1),
            0,
            0,
            1
        );
        console.log("after refundable", testToken2);
        testTokenInstanceRefund = SuperMemeRefundableBondingCurve(
                testToken2
            );

        vm.stopPrank();
    }

    function testDeploy() public {
        assertEq(testTokenInstanceDegen.totalSupply(), 200000000 ether);
        assertEq(testTokenInstanceRefund.totalSupply(), 200000000 ether);
    }

    function testPriceWithBuyTokensDegen() public {
        vm.startPrank(addr1);
        for (uint256 i = 1; i < 160; i++) {
            uint256 amount = 5000000;
            uint256 cost = testTokenInstanceDegen.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            testTokenInstanceDegen.buyTokens{value: totalCost}(amount, 100, totalCost);
            uint256 pricePerToken = testTokenInstanceDegen.calculateCost(1);
            uint256 totalSupply = testTokenInstanceDegen.totalSupply();
            //
            //
        }
    }

    function testPriceWithBuyTokensRefundable() public {
        vm.startPrank(addr1);
        for (uint256 i = 0; i < 160; i++) {
            uint256 amount = 5000000;
            uint256 cost = testTokenInstanceRefund.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            testTokenInstanceRefund.buyTokens{value: totalCost}(amount, 100, totalCost);
            uint256 pricePerToken = testTokenInstanceRefund.calculateCost(1);
            uint256 totalSupply = testTokenInstanceRefund.totalSupply();
        }
    }

    function testSendToDexDegen() public {
        vm.startPrank(addr1);
        for (uint256 i = 0; i < 160; i++) {
            uint256 amount = 5000000;
            uint256 cost = testTokenInstanceDegen.calculateCost(amount);
            uint256 tax = cost / 100;
            uint256 totalCost = cost + tax;
            testTokenInstanceDegen.buyTokens{value: totalCost}(amount, 100, totalCost);
            uint256 pricePerToken = testTokenInstanceDegen.calculateCost(1);
            uint256 totalSupply = testTokenInstanceDegen.totalSupply();
            //
            //
        }
        //
        uint256 balance = address(testTokenInstanceDegen).balance;
        testTokenInstanceDegen.sendToDex();
        address weth = router.WETH();

        address[] memory path = new address[](2);
        path[0] = address(testTokenInstanceDegen);
        path[1] = (weth);

        uint256[] memory amounts;
        amounts = router.getAmountsOut(1000000 ether, path);
        
        vm.stopPrank();

    }
}
