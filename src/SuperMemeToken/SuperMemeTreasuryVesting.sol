// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract SuperMemeTreasuryVesting is Ownable {

    IERC20 public immutable stakingToken;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastUnstakeTime;
    uint256 public totalSupply;

    uint256 private constant SCALE = 1e18;
    uint256 private rewardIndex;
    mapping(address => uint256) private rewardIndexOf;
    mapping(address => uint256) private earned;

    uint256 public allTimeRevenueCollected;
    uint256 public allTimeRewardsDistributed;

    uint256[2] public teamLocks = [365 days, 730 days];
    uint256[2] public treasuryLocks = [365 days, 730 days];
    uint256[2] public developmentLocks = [30 days, 730 days];
    uint256[2] public marketingLocks = [30 days, 730 days];
    uint256[2] public liquidityLocks = [0 days, 730 days];
    uint256[2] public airdropLocks = [30 days, 30 days];
    // uint256[2] public advisorLocks = [180 days, 365 days];
    // uint256[2] public advisor2Locks = [30 days, 365 days];

    address public constant TEAM = 0xEcd2369e23Fb21458aa41f7fb1cB1013913D97EA;
    address public constant TREASURY = 0xc674f8D0bBC54f8eB7e7c32d6b6E11dC07f01Af5;
    address public constant DEVELOPMENT = 0x86F13a708347611346B37457D3A5666e33630dA6;
    address public constant MARKETING = 0x8614a5372E87511a93568d756469CCc06c5a3393;
    address public constant LIQUIDITY = 0x4049C6d09D7c1C93D70181650279100E4D018D3D;
    address public constant AIRDROP = 0x137d220Fb68F637e98773E39aB74E466C773AC20;
    address public constant ADVISOR = 0xb1683022cDE0d8d69b4c458F52610f6Fd4e83D66;


    uint256 public constant TREASURY_AMOUNT = 200_000_000 ether;
    uint256 public constant DEVELOPMENT_AMOUNT = 80_000_000 ether;
    uint256 public constant MARKETING_AMOUNT = 90_000_000 ether;
    uint256 public constant LIQUIDITY_AMOUNT = 180_000_000 ether;
    uint256 public constant AIRDROP_AMOUNT = 30_000_000 ether;
    uint256 public constant TEAM_AMOUNT = 150_000_000 ether;

    // Mapping of advisors to their individual vesting schedules
    mapping(address => Vesting) public advisorVestingSchedule;
    mapping(address => Vesting) public vestingSchedule;

    mapping(address => uint256) public totalUnlockedAndClaimed;

    address[] public advisors;

    uint256 public tgeDate;

    struct Vesting {
        uint256 cliffEnd;
        uint256 vestingEnd;
        uint256 totalAmount;
    }

    constructor(address _stakingToken, uint256 _tgeDate) Ownable(msg.sender){
        stakingToken = IERC20(_stakingToken);
        tgeDate = _tgeDate;
        initializeVestingSchedules();
    }

    // --- External/Public Functions ---

    function addAdvisor(address advisor, uint256 amount, uint256 _cliffDuration, uint256 _vestingDuration) external {
        require(msg.sender == ADVISOR, "Only owner can add advisor");
        require(advisorVestingSchedule[advisor].vestingEnd == 0, "Advisor already added");

        // Initialize advisor vesting schedule
        advisors.push(advisor);
        advisorVestingSchedule[advisor] = Vesting(
            tgeDate + _cliffDuration,
            tgeDate + _cliffDuration + _vestingDuration,
            amount
        );

        _updateRewards(advisor);
        // Update contract state
        balance[advisor] += amount;
        totalSupply += amount;
        totalUnlockedAndClaimed[advisor] = 0;

        // Transfer tokens from msg.sender to the contract
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    function collectRevenue() external payable {
        uint256 reward = msg.value;
        if (totalSupply == 0) {
            return;
        }
        rewardIndex += (reward * SCALE) / totalSupply;
        allTimeRevenueCollected += reward;
    }
    function stake(uint256 amount) external {
        require(isEligibleForVesting(msg.sender), "Not eligible for vesting");
        if (advisorVestingSchedule[msg.sender].vestingEnd > 0) {
            require(advisorVestingSchedule[msg.sender].totalAmount == amount, "Amount does not match advisor vesting amount");
        } else {
            require(vestingSchedule[msg.sender].totalAmount == amount, "Amount does not match vesting amount");
        }
        stakingToken.transferFrom(msg.sender, address(this), amount);
        _updateRewards(msg.sender);

        balance[msg.sender] += amount;
        totalSupply += amount;
        totalUnlockedAndClaimed[msg.sender] = 0;
    }

    function unstake() external {
        require(balance[msg.sender] > 0, "Not staked yet :) ");
        uint256 amount = getUnlockedAmount(msg.sender);
        require(block.timestamp > getCliffEnd(msg.sender), "Cliff period not reached");
        require(amount > 0, "No unlocked amount");
        claim();
        stakingToken.transfer(msg.sender, amount);
        
        
        balance[msg.sender] -= amount;
        totalSupply -= amount;
        totalUnlockedAndClaimed[msg.sender] += amount;        
    }

    function claim() public returns (uint256) {
        require(balance[msg.sender] > 0, "Not staked yet :) ");
        _updateRewards(msg.sender);
        uint256 reward = earned[msg.sender];

        if (reward > 0) {
            earned[msg.sender] = 0;
            payable(msg.sender).transfer(reward);
            allTimeRewardsDistributed += reward;
        }
        return reward;

    }

    function calculateRewardsEarned(address account) external view returns (uint256) {
        return earned[account] + _calculateRewards(account);
    }

    function getUnlockedAmount(address account) public view returns (uint256) {
        Vesting memory vesting = getVestingSchedule(account);
        if (block.timestamp < vesting.cliffEnd) {
            return 0;
        } else if (block.timestamp >= vesting.vestingEnd) {
            return balance[account];
        } else {
            uint256 vestingDuration = vesting.vestingEnd - vesting.cliffEnd;
            uint256 timeVested = block.timestamp - vesting.cliffEnd;
            return ((vesting.totalAmount * timeVested) / vestingDuration) - totalUnlockedAndClaimed[account];
        }
    }


    function initializeVestingSchedules() internal {
        vestingSchedule[TEAM] = Vesting(tgeDate + teamLocks[0], tgeDate + teamLocks[1] + teamLocks[0], TEAM_AMOUNT);
        vestingSchedule[TREASURY] = Vesting(tgeDate + treasuryLocks[0], tgeDate + treasuryLocks[1] + treasuryLocks[0], TREASURY_AMOUNT);
        vestingSchedule[DEVELOPMENT] = Vesting(tgeDate + developmentLocks[0], tgeDate + developmentLocks[1] + developmentLocks[0], DEVELOPMENT_AMOUNT);
        vestingSchedule[MARKETING] = Vesting(tgeDate + marketingLocks[0], tgeDate + marketingLocks[1] + marketingLocks[0], MARKETING_AMOUNT);
        vestingSchedule[LIQUIDITY] = Vesting(tgeDate + liquidityLocks[0], tgeDate + liquidityLocks[1] + liquidityLocks[0], LIQUIDITY_AMOUNT);
        vestingSchedule[AIRDROP] = Vesting(tgeDate + airdropLocks[0], tgeDate + airdropLocks[1] + airdropLocks[0], AIRDROP_AMOUNT);

        
    }

    function _calculateRewards(address account) private view returns (uint256) {
        uint256 shares = balance[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / SCALE;
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function isEligibleForVesting(address account) internal view returns (bool) {
        return account == TEAM || account == TREASURY || account == DEVELOPMENT || account == MARKETING || account == LIQUIDITY || account == AIRDROP || advisorVestingSchedule[account].vestingEnd > 0;
    }

    function getVestingSchedule(address account) internal view returns (Vesting memory) {
        if (advisorVestingSchedule[account].vestingEnd > 0) {
            return advisorVestingSchedule[account];
        } else {
            if (account == TEAM) {
                return vestingSchedule[TEAM];
            } else if (account == TREASURY) {
                return vestingSchedule[TREASURY];
            } else if (account == DEVELOPMENT) {
                return vestingSchedule[DEVELOPMENT];
            } else if (account == MARKETING) {
                return vestingSchedule[MARKETING];
            } else if (account == LIQUIDITY) {
                return vestingSchedule[LIQUIDITY];
            } else if (account == AIRDROP) {
                return vestingSchedule[AIRDROP];
            }
        }
    }

    function getCliffEnd(address account) internal view returns (uint256) {
        console.log("getVestingSchedule(account).cliffEnd: ", getVestingSchedule(account).cliffEnd);
        return getVestingSchedule(account).cliffEnd;
    }
}

