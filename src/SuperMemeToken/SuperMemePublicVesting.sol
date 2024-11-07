// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperMemePublicVesting is ERC721, ERC721Enumerable {
    IERC20 public immutable stakingToken;
    uint256 public nextTokenId;
    
    struct StakeInfo {
        uint256 amount;
        uint256 lockEnd;
        uint256 revenueShareBonus;
        uint256 sharesAmount;
        uint256 rewardIndex;
        uint256 earned;
    }
    
    mapping(uint256 => StakeInfo) public stakeInfo;

    // Lock periods and corresponding bonuses
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = 90 days;
    uint256 public constant SIX_MONTHS = 180 days;
    uint256 public constant BONUS_THREE_MONTHS = 500; // 5% bonus
    uint256 public constant BONUS_SIX_MONTHS = 1500;  // 15% bonus

    uint256 bonusScale = 10000;

    // Reward distribution variables
    uint256 public rewardIndex; // Accumulated reward per token
    uint256 public totalStaked; // Total tokens staked in the contract
    uint256 private constant SCALE = 1e18;

    uint256 totalSharesAmount;

    event Staked(address indexed user, uint256 amount, uint256 lockPeriod, uint256 tokenId);
    event Unstaked(address indexed user, uint256 amount, uint256 tokenId);
    event Claimed(address indexed user, uint256 amount);

    constructor(address _stakingToken) ERC721("SuperMemeStakeNFT", "SMNFT") {
        stakingToken = IERC20(_stakingToken);
    }

    // --- External/Public Functions ---

    function stake(uint256 amount, uint256 lockPeriod) external returns (uint256) {
        require(amount > 0, "Stake amount must be greater than zero");
        require(
            lockPeriod == ONE_MONTH || lockPeriod == THREE_MONTHS || lockPeriod == SIX_MONTHS,
            "Invalid lock period"
        );

        uint256 revenueShareBonus = 1;
        if (lockPeriod == THREE_MONTHS) {
            revenueShareBonus = BONUS_THREE_MONTHS;
        } else if (lockPeriod == SIX_MONTHS) {
            revenueShareBonus = BONUS_SIX_MONTHS;
        }

        // Transfer staking tokens
        stakingToken.transferFrom(msg.sender, address(this), amount);

        uint256 receivedShares = amount * revenueShareBonus / bonusScale;
        totalSharesAmount += receivedShares;
        totalStaked += amount;

        // Mint NFT for this stake
        uint256 tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);

        // Record stake details
        stakeInfo[tokenId] = StakeInfo({
            amount: amount,
            lockEnd: block.timestamp + lockPeriod,
            revenueShareBonus: revenueShareBonus,
            sharesAmount: receivedShares,
            rewardIndex: rewardIndex,
            earned: 0
        });
        _updateRewards(tokenId);
        emit Staked(msg.sender, amount, lockPeriod, tokenId);

        return tokenId;
    }

    function unstake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this stake");

        StakeInfo memory stakeMem = stakeInfo[tokenId];
        require(block.timestamp >= stakeMem.lockEnd, "Lock period not over");

        _updateRewards(tokenId);
        claimReward(tokenId);

        totalSharesAmount -= stakeMem.sharesAmount;
        totalStaked -= stakeMem.amount;

        _burn(tokenId);
        delete stakeInfo[tokenId];

        stakingToken.transfer(msg.sender, stakeMem.amount);
        emit Unstaked(msg.sender, stakeMem.amount, tokenId);
    }


    // Add rewards to the contract and update reward index
    function collectRevenue() external payable {
        require(totalStaked > 0, "No staked tokens");
        uint256 amount = msg.value;
        rewardIndex += (amount * SCALE) / totalSharesAmount;
    }

    // --- Internal/Private Functions ---
    function claimReward(uint256 _tokenId) public returns (uint256) {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of this stake");

        StakeInfo storage stake = stakeInfo[_tokenId];
        _updateRewards(_tokenId);
        uint256 reward = stake.earned;

        if (reward > 0) {
            stake.earned = 0;
            payable(msg.sender).transfer(reward);
        }
        emit Claimed(msg.sender, reward);
        return reward;
    }
    function _updateRewards(uint256 _tokenId) private {
        StakeInfo storage stake = stakeInfo[_tokenId];
        stake.earned += _calculateRewards(_tokenId);
        stake.rewardIndex = rewardIndex;
    }

    function _calculateRewards(uint256 _tokenId) public view returns (uint256) {
        StakeInfo memory stake = stakeInfo[_tokenId];
        uint256 shares = stake.sharesAmount;
        return (shares * (rewardIndex - stake.rewardIndex)) / SCALE;
    }


    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


