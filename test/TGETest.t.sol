pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factories/DegenFactory.sol";
import "../src/Factories/LockingCurveFactory.sol";
import "../src/Factories/RefundableFactory.sol";
import "../src/SuperMemeDegenBondingCurve.sol";
import "../src/Factories/SuperMemeRegistry.sol";
import "../src/SuperMemeRevenueCollector.sol";
import "../src/Factories/CommunityLockFactory.sol";
import "../src/SuperMemeToken/SuperMeme.sol";
import "../src/SuperMemeToken/SuperMemePublicVesting.sol";
import "../src/SuperMemeToken/SuperMemeTreasuryVesting.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

contract TGETest is Test {
    uint256 public dummyBuyAmount = 1000;
    uint256 public dummyBuyAmount2 = 1000000;

    IUniswapFactory public uniswapFactory;
    RefundableFactory public refundableFactory;
    DegenFactory public degenFactory;
    LockingCurveFactory public lockingCurveFactory;
    SuperMemeDegenBondingCurve public degenbondingcurve;
    SuperMemeRegistry public registry;
    SuperMemeRevenueCollector public revenueCollector;
    CommunityLockFactory public communityLockFactory;

    SuperMemePublicVesting public publicVesting;
    SuperMemeTreasuryVesting public treasuryVesting;
    SuperMeme public spr;

    SuperMemeDegenBondingCurve public degenbondingcurve2;
    SuperMemeRefundableBondingCurve public refundableBondingCurve;
    SuperMemeLockingCurve public lockingCurve;

    uint256 public createTokenRevenue = 0.0008 ether;

    address public constant SEED = 0xA1A1a1a1A1A1A1A1A1a1a1a1a1a1A1A1a1A1a1a1;
    uint256 public constant SEED_AMOUNT = 30_000_000 ether;

    address public constant OPENS = 0xb2b2b2b2b2B2b2B2B2b2b2B2B2b2B2B2b2b2b2b2;
    uint256 public constant OPENS_AMOUNT = 133_000_000 ether;

    address public constant KOL = 0xc3c3c3c3c3c3c3c3c3C3C3c3C3C3C3c3C3C3c3c3;
    uint256 public constant KOL_AMOUNT = 27_000_000 ether;

    address public constant PUBLIC = 0xd4d4d4D4D4d4d4d4d4D4d4D4d4d4d4d4d4d4D4d4;
    uint256 public constant PUBLIC_AMOUNT = 50_000_000 ether;

    address public constant TEAM = 0x34567890abCdEF1234567890abcDeF1234567890;
    uint256 public constant TEAM_AMOUNT = 150_000_000 ether;

    address public constant TREASURY =
        0x234567890abCDEf1234567890aBCdEf123456789;
    uint256 public constant TREASURY_AMOUNT = 200_000_000 ether;

    address public constant DEVELOPMENT =
        0x234567890abCdeF1234567890AbCDef123456788;
    uint256 public constant DEVELOPMENT_AMOUNT = 80_000_000 ether;

    address public constant MARKETING =
        0x34567890abCDEf1234567890aBCDEf1234567892;
    uint256 public constant MARKETING_AMOUNT = 90_000_000 ether;

    address public constant LIQUIDITY =
        0x4567890abcdEf1234567890ABcDEF12345678901;
    uint256 public constant LIQUIDITY_AMOUNT = 180_000_000 ether;

    address public constant AIRDROP =
        0x567890abCdeF1234567890abCdEF123456789012;
    uint256 public constant AIRDROP_AMOUNT = 30_000_000 ether;

    address public constant ADVISOR =
        0x67890ABCDEf1234567890abcdef1234567890123;
    uint256 public constant ADVISOR_AMOUNT = 30_000_000 ether;

    address public owner = address(0x123);
    address public addr1 = address(0x456);
    address public addr2 = address(0x789);
    address public addr3 = address(0x101112);

    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant SIX_MONTHS = 180 days;
    uint256 public constant BONUS_THREE_MONTHS = 500; // 5% bonus
    uint256 public constant BONUS_SIX_MONTHS = 1500;  // 15% bonus

    uint256 createTokenRevenueAfterJackpot;


    function setUp() public {
        vm.deal(owner, 1000 ether);

        vm.deal(addr1, 1000 ether);
        vm.deal(addr2, 1000 ether);
        vm.deal(addr3, 1000 ether);
        vm.deal(SEED, 1000 ether);
        vm.deal(OPENS, 1000 ether);
        vm.deal(KOL, 1000 ether);
        vm.deal(PUBLIC, 1000 ether);
        vm.deal(TEAM, 1000 ether);
        vm.deal(TREASURY, 1000 ether);
        vm.deal(DEVELOPMENT, 1000 ether);
        vm.deal(MARKETING, 1000 ether);
        vm.deal(LIQUIDITY, 1000 ether);
        vm.deal(AIRDROP, 1000 ether);
        vm.deal(ADVISOR, 1000 ether);

        uint256 createTokenRevenue = 0.0008 ether;
        

        spr = new SuperMeme();

        //imitate the minted tokens addresses so we can use them to call transfer tokens
        publicVesting = new SuperMemePublicVesting(address(spr));
        treasuryVesting = new SuperMemeTreasuryVesting(address(spr));

        revenueCollector = new SuperMemeRevenueCollector(
            address(spr),
            address(publicVesting),
            address(treasuryVesting)
        );

        registry = new SuperMemeRegistry();
        degenFactory = new DegenFactory(address(registry));
        refundableFactory = new RefundableFactory(address(registry));
        lockingCurveFactory = new LockingCurveFactory(address(registry));
        communityLockFactory = new CommunityLockFactory(address(registry));

        degenFactory.setRevenueCollector(address(revenueCollector));
        refundableFactory.setRevenueCollector(address(revenueCollector));
        lockingCurveFactory.setRevenueCollector(address(revenueCollector));
        communityLockFactory.setRevenueCollector(address(revenueCollector));

        degenFactory.setCreateTokenRevenue(createTokenRevenue);
        refundableFactory.setCreateTokenRevenue(createTokenRevenue);
        lockingCurveFactory.setCreateTokenRevenue(createTokenRevenue);
        communityLockFactory.setCreateTokenRevenue(createTokenRevenue);

        registry.setFactory(address(degenFactory));
        registry.setFactory(address(refundableFactory));
        registry.setFactory(address(lockingCurveFactory));
        registry.setFactory(address(communityLockFactory));

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

        vm.startPrank(addr1);

        address DegenToken = degenFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme", "MEME", false, 0, address(addr1), 0, 0);
        assertEq(degenFactory.tokenAddresses(0), DegenToken);
        degenbondingcurve2 = SuperMemeDegenBondingCurve(DegenToken);

        address RefundableToken = refundableFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme2", "MEM", 0, address(addr1), 0);

        assertEq(refundableFactory.tokenAddresses(0), RefundableToken);
        refundableBondingCurve = SuperMemeRefundableBondingCurve(
            RefundableToken
        );

        address LockingToken = lockingCurveFactory.createToken{
            value: createTokenRevenue
        }("SuperMeme3", "MEM", 0, address(addr1), 0, 1 days);
        lockingCurve = SuperMemeLockingCurve(LockingToken);

        createTokenRevenueAfterJackpot = (createTokenRevenue * 3) * 99 / 100;
    }
    function testDeploy() public {
        assertEq(degenFactory.revenueCollector(), (address(revenueCollector)));
        assertEq(
            refundableFactory.revenueCollector(),
            (address(revenueCollector))
        );
        assertEq(
            lockingCurveFactory.revenueCollector(),
            (address(revenueCollector))
        );
        assertEq(degenbondingcurve2.devAddress(), address(addr1));
        assertEq(refundableBondingCurve.devAddress(), address(addr1));
        assertEq(lockingCurve.devAddress(), address(addr1));
        console.log("total expected revenue", createTokenRevenue * 3);
        console.log(
            "revenue collector balance",
            address(revenueCollector).balance
        );
        console.log(revenueCollector.totalEtherCollected());
        
    }

    function testForTreasuryStaking() public {
        vm.startPrank(TREASURY);
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);

        revenueCollector.distrubuteRevenue();
        assertEq(revenueCollector.totalEtherCollected(), 0);
        assertEq(treasuryVesting.allTimeRevenueCollected(), (createTokenRevenue * 3) * 99 / 100);
        vm.stopPrank();

    }

    function testForTreasuryUnStaking() public {
        vm.startPrank(TREASURY);
        console.log("before staking", spr.balanceOf(address(TREASURY)));
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);
        
        revenueCollector.distrubuteRevenue();
        assertEq(revenueCollector.totalEtherCollected(), 0);
        assertEq(treasuryVesting.allTimeRevenueCollected(), createTokenRevenueAfterJackpot);
        vm.stopPrank();

        vm.startPrank(TREASURY);
        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        vm.stopPrank();

        vm.startPrank(TEAM);
        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        vm.stopPrank();

        vm.warp(block.timestamp + 730 days);

        vm.startPrank(TREASURY);
        console.log("before unstake sadfasfasd", spr.balanceOf(address(TREASURY)));
        treasuryVesting.unstake();
        console.log("after unstake aaaaaaaaaaaaaa", spr.balanceOf(address(TREASURY)));
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT/2);
    }


    function testForTreasuryStakingRewards() public {
        vm.startPrank(TREASURY);
        console.log("before staking", spr.balanceOf(address(TREASURY)));
        spr.approve(address(treasuryVesting), TREASURY_AMOUNT);
        treasuryVesting.stake(TREASURY_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TREASURY)), TREASURY_AMOUNT);
        vm.stopPrank();

        vm.startPrank(TEAM);
        spr.approve(address(treasuryVesting), TEAM_AMOUNT);
        treasuryVesting.stake(TEAM_AMOUNT);
        assertEq(spr.balanceOf(address(treasuryVesting)), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.totalSupply(), TEAM_AMOUNT + TREASURY_AMOUNT);
        assertEq(treasuryVesting.balance(address(TEAM)), TEAM_AMOUNT);

        vm.startPrank(addr1);

        revenueCollector.distrubuteRevenue();
        vm.stopPrank();

        vm.startPrank(TREASURY);
        uint256 ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        uint256 ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 expectedTreasuryRewards = createTokenRevenueAfterJackpot * 200_000_000 ether / 350_000_000 ether;
        uint256 receivedTreasuryRewards = ethBalanceofTreasuryAfterClaim - ethBalanceofTreasuryBeforeClaim;
        assertApproxEqAbs(receivedTreasuryRewards, expectedTreasuryRewards, 0.000001 ether);
        assertApproxEqAbs(address(treasuryVesting).balance, createTokenRevenueAfterJackpot * 150_000_000 ether / 350_000_000 ether,0.000001 ether);

        vm.startPrank(addr1);
        uint256 hundredether = 100 ether;
        payable(revenueCollector).call{value: hundredether, gas: 3000000}("");
        uint256 collectedRevenueAfterJackpot = 99 ether;
        revenueCollector.distrubuteRevenue();
        vm.stopPrank();


        vm.startPrank(TREASURY);

        vm.expectRevert("Cliff period not reached");
        treasuryVesting.unstake();
        console.log("vesting reward balance", address(treasuryVesting).balance);
        vm.warp(block.timestamp + 730 days);
        ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.unstake();
        ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 teamRewards = treasuryVesting.calculateRewardsEarned(TEAM);
        expectedTreasuryRewards = (collectedRevenueAfterJackpot  * 200_000_000 / 350_000_000);
        receivedTreasuryRewards = ethBalanceofTreasuryAfterClaim - ethBalanceofTreasuryBeforeClaim;
        assertApproxEqAbs(receivedTreasuryRewards, expectedTreasuryRewards, 0.0001 ether);
        assertEq(spr.balanceOf(address(TREASURY)), TREASURY_AMOUNT/2);
        assertEq(spr.balanceOf(address(treasuryVesting)), TREASURY_AMOUNT/2 + TEAM_AMOUNT);
        vm.stopPrank();

        vm.startPrank(addr1);
        payable(revenueCollector).call{value: hundredether, gas: 3000000}("");
        collectedRevenueAfterJackpot += 99 ether;
        revenueCollector.distrubuteRevenue();
        vm.stopPrank();

        vm.warp(block.timestamp + 150 days);

        vm.startPrank(TREASURY);
        ethBalanceofTreasuryBeforeClaim = address(TREASURY).balance;
        treasuryVesting.claim();
        ethBalanceofTreasuryAfterClaim = address(TREASURY).balance;
        uint256 sprBalanceOfTreasuryInVesting = spr.balanceOf(address(TREASURY));
        expectedTreasuryRewards = collectedRevenueAfterJackpot * 200_000_000 / 350_000_000;
        assertApproxEqAbs(sprBalanceOfTreasuryInVesting, treasuryVesting.balance(address(TREASURY)), 0.0001 ether);


        uint256 unstakableAmount = treasuryVesting.getUnlockedAmount(address(TREASURY));
        assertEq(unstakableAmount, TREASURY_AMOUNT * (150 + 365) / 730 - treasuryVesting.totalUnlockedAndClaimed(address(TREASURY)));
        treasuryVesting.unstake();


    }

    function testForPublicStaking() public {
        vm.startPrank(PUBLIC);
        spr.transfer(addr1, 100 ether);
        spr.transfer(addr2, 200 ether);
        spr.transfer(addr3, 300 ether);
        vm.stopPrank();

        vm.startPrank(addr1);
        spr.approve(address(publicVesting), 100 ether);
        uint256 tokenId1 = publicVesting.stake(100 ether, ONE_MONTH);
        assertEq(spr.balanceOf(address(publicVesting)), 100 ether);
        assertEq(publicVesting.ownerOf(tokenId1), addr1);

    }
}
