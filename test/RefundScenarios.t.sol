pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/SuperMemeRefundableBondingCurve.sol";
import "../src/SuperMemeFactory.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
//import uniswap pair
import {IUniswapV2Pair} from "../src/Interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";

contract RefundScenariosTest is Test {

    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;
    IUniswapV2Pair public pair;
    IUniswapFactory public unifactory;    
    SuperMemeFactory public factory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    uint256 public createTokenRevenue = 0.00001 ether;
    IUniswapV2Router02 public router;
    SuperMemeDegenBondingCurve public tTokenInstanceDegen;
    SuperMemeRefundableBondingCurve public tTokenInstanceRefund;
    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);


    function setUp() public {
        console.log("inside setup");
        uint256 createTokenRevenue = 0.00001 ether;
        router = IUniswapV2Router02(address(0x5633464856F58Dfa9a358AfAf49841FEE990e30b));
        address fakeContract = address(0x12123123);
        unifactory = IUniswapFactory(address(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6));
        vm.deal(owner, 1000 ether);
        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.startPrank(addr1);
        factory = new SuperMemeFactory();

        console.log("Factory address: ", address(factory));
        address testToken = factory.createToken{value: createTokenRevenue}(
            "SuperMeme",
            "MEME",
            false,
            0,
            address(addr1),
            0,
            0,
            1
        );
        console.log("Token address: ", testToken);
        tTokenInstanceRefund = SuperMemeRefundableBondingCurve(
                testToken
            );
        console.log("Token address: ", testToken);
        vm.stopPrank();
    }

    function testDeploy() public {
        assertEq(tTokenInstanceRefund.totalSupply(), 200000000 ether);
    }

    function testBuyerRefundsImmediately() public {
        vm.startPrank(addr1);
        uint256 cost = tTokenInstanceRefund.calculateCost(dummyBuyAmount);
        uint256 tax = cost / 100;
        uint256 slippage = 100;
        uint256 totalCost = cost + tax;
        tTokenInstanceRefund.buyTokens{value: totalCost + slippage}(dummyBuyAmount, 100, totalCost);
        assertEq(tTokenInstanceRefund.balanceOf(addr1), dummyBuyAmount * 10 ** 18);

    }
}