pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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
    ERC20 public mockToken;
    ERC721 public mockNFT;

    uint256 public totalEtherCollected;
    uint256 public nftShare;
    uint256 public lockDuration = 1 weeks;

    mapping(uint256 => uint256) public nftLocks;

    constructor() Ownable(msg.sender) {}

    receive() external payable {
        totalEtherCollected += msg.value;
        nftShare += msg.value / 100; 
    }
    function distrubuteRevenue() public payable {}

    function collectNFTJackpot(uint256 _tokenId) public {
        require(
            mockNFT.ownerOf(_tokenId) == msg.sender,
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

    function setMockToken(address _mockToken) public onlyOwner {
        mockToken = ERC20(_mockToken);
    }

    function setMockNFT(address _mockNFT) public onlyOwner {
        mockNFT = ERC721(_mockNFT);
    }

    function setLockDuration(uint256 _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }
}
