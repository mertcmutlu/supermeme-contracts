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
    uint256[2] public advisorLocks = [180 days, 365 days];
    uint256[2] public advisor2Locks = [30 days, 365 days];

    address public constant TEAM = 0x34567890abCdEF1234567890abcDeF1234567890;
    address public constant TREASURY = 0x234567890abCDEf1234567890aBCdEf123456789;
    address public constant DEVELOPMENT = 0x234567890abCdeF1234567890AbCDef123456788;
    address public constant MARKETING = 0x34567890abCDEf1234567890aBCDEf1234567892;
    address public constant LIQUIDITY = 0x4567890abcdEf1234567890ABcDEF12345678901;
    address public constant AIRDROP = 0x567890abCdeF1234567890abCdEF123456789012;

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

    struct Vesting {
        uint256 cliffEnd;
        uint256 vestingStart;
        uint256 vestingEnd;
        uint256 totalAmount;
    }

    constructor(address _stakingToken) Ownable(msg.sender){
        stakingToken = IERC20(_stakingToken);
        initializeVestingSchedules();
        
    }

    // --- External/Public Functions ---

    function addAdvisor(address advisor, uint256 amount) onlyOwner external {
        require(advisorVestingSchedule[advisor].vestingEnd == 0, "Advisor already added");

        // Initialize advisor vesting schedule
        advisors.push(advisor);
        advisorVestingSchedule[advisor] = Vesting(
            block.timestamp + advisorLocks[0],
            block.timestamp + advisorLocks[0],
            block.timestamp + advisorLocks[1],
            amount
        );

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
        stakingToken.transfer(msg.sender, amount);
        _updateRewards(msg.sender);
        claim();
        

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
        vestingSchedule[TEAM] = Vesting(block.timestamp + teamLocks[0], block.timestamp, block.timestamp + teamLocks[1] + teamLocks[0], TEAM_AMOUNT);
        vestingSchedule[TREASURY] = Vesting(block.timestamp + treasuryLocks[0], block.timestamp, block.timestamp + treasuryLocks[1] + treasuryLocks[0], TREASURY_AMOUNT);
        vestingSchedule[DEVELOPMENT] = Vesting(block.timestamp + developmentLocks[0], block.timestamp, block.timestamp + developmentLocks[1]+ developmentLocks[0], DEVELOPMENT_AMOUNT);
        vestingSchedule[MARKETING] = Vesting(block.timestamp + marketingLocks[0], block.timestamp, block.timestamp + marketingLocks[1]+ marketingLocks[0], MARKETING_AMOUNT);
        vestingSchedule[LIQUIDITY] = Vesting(block.timestamp + liquidityLocks[0], block.timestamp, block.timestamp + liquidityLocks[1]+ liquidityLocks[0], LIQUIDITY_AMOUNT);
        vestingSchedule[AIRDROP] = Vesting(block.timestamp + airdropLocks[0], block.timestamp, block.timestamp + airdropLocks[1]+ airdropLocks[0], AIRDROP_AMOUNT);
    }

    function _calculateRewards(address account) private view returns (uint256) {
        uint256 shares = balance[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / SCALE;
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
        console.log("earned[account]: ", earned[account]);
    }

    function isEligibleForVesting(address account) internal view returns (bool) {
        return account == TEAM || account == TREASURY || account == DEVELOPMENT || account == MARKETING || account == LIQUIDITY || account == AIRDROP || advisorVestingSchedule[account].vestingEnd > 0;
    }

    function getVestingSchedule(address account) internal view returns (Vesting memory) {
        //check if the account is advisor or not
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
        return getVestingSchedule(account).cliffEnd;
    }
}

