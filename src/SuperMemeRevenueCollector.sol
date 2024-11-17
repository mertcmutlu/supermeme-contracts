pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SuperMemeToken/SuperMemePublicStaking.sol";
import "./SuperMemeToken/SuperMemeTreasuryVesting.sol";
import "forge-std/console.sol";

/*
   ▄████████ ███    █▄     ▄███████▄    ▄████████    ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████ 
  ███    ███ ███    ███   ███    ███   ███    ███   ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ 
  ███    █▀  ███    ███   ███    ███   ███    █▀    ███    ███ ███   ███   ███   ███    █▀  ███   ███   ███   ███    █▀  
  ███        ███    ███   ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀ ███   ███   ███  ▄███▄▄▄     ███   ███   ███  ▄███▄▄▄     
▀███████████ ███    ███ ▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███   ███   ███ ▀▀███▀▀▀     ███   ███   ███ ▀▀███▀▀▀     
         ███ ███    ███   ███          ███    █▄  ▀███████████ ███   ███   ███   ███    █▄  ███   ███   ███   ███    █▄  
   ▄█    ███ ███    ███   ███          ███    ███   ███    ███ ███   ███   ███   ███    ███ ███   ███   ███   ███    ███ 
 ▄████████▀  ████████▀   ▄████▀        ██████████   ███    ███  ▀█   ███   █▀    ██████████  ▀█   ███   █▀    ██████████ 
                                                    ███    ███                                                           
*/

contract SuperMemeRevenueCollector is Ownable {
    ERC20 public SPR;
    ERC721 public SuperDuperNFT;

    SuperMemePublicStaking public publicStaking;
    SuperMemeTreasuryVesting public treasuryVesting;

    uint256 public totalEtherCollected;
    uint256 public nftShare;
    uint256 public lockDuration = 1 weeks;

    mapping(uint256 => uint256) public nftLocks;

    constructor(address _sprToken, address _publicStaking, address _treasuryVesting) Ownable(msg.sender) {
        publicStaking = SuperMemePublicStaking(_publicStaking);
        treasuryVesting = SuperMemeTreasuryVesting(_treasuryVesting);
        SPR = ERC20(_sprToken);
    }

    receive() external payable {
        totalEtherCollected += (msg.value - msg.value / 100);
        nftShare += msg.value / 100; 
    }
    function distributeRevenue() public payable {
        uint256 balanceOfTreasury = SPR.balanceOf(address(treasuryVesting));
        uint256 balanceOfPublicStaking = SPR.balanceOf(address(publicStaking));
        uint256 totalBalance = balanceOfTreasury + balanceOfPublicStaking;
        uint256 treasuryShare = (totalEtherCollected * balanceOfTreasury) / totalBalance;
        uint256 publicShare = totalEtherCollected - treasuryShare;
        if (treasuryShare > 0) {
            treasuryVesting.collectRevenue{value: treasuryShare}();
        }
        if (publicShare > 0) {
            publicStaking.collectRevenue{value: publicShare}();
        }
        totalEtherCollected = 0;
    }

    function collectNFTJackpot(uint256 _tokenId) public {
        require(
            SuperDuperNFT.ownerOf(_tokenId) == msg.sender,
            "NFT not owned by sender"
        );
        require(
            nftLocks[_tokenId] < block.timestamp || nftLocks[_tokenId] == 0,
            "NFT is locked"
        );
        uint256 jackpot = nftShare;
        nftShare = 0;
        nftLocks[_tokenId] = block.timestamp + lockDuration;
        payable(msg.sender).transfer(jackpot);
    }

    function remainingLockTime(uint256 _tokenId) public view returns (uint256) {
        return
            nftLocks[_tokenId] - block.timestamp > 0
                ? nftLocks[_tokenId] - block.timestamp
                : 0;
    }

    function setSPRToken(address _sprToken) public onlyOwner {
        SPR = ERC20(_sprToken);
    }

    function setNFT(address _superduperNFT) public onlyOwner {
        SuperDuperNFT = ERC721(_superduperNFT);
    }

    function setLockDuration(uint256 _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }
}