// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract SuperMeme is ERC20 {
    address public constant SEED = 0xB7918aF63C7Db61F1c1152C3bc4EfBd9F36dEab6;
    uint256 public constant SEED_AMOUNT = 30_000_000 ether;

    address public constant OPENS = 0x65C5d8417AF968CB711A5eD3220E665e617EF4A6;
    uint256 public constant OPENS_AMOUNT = 133_000_000 ether;

    address public constant KOL = 0xa4fbf15678aD52ea675C4FA4EA0f8617781D6Ef4;
    uint256 public constant KOL_AMOUNT = 27_000_000 ether;

    address public constant PUBLIC = 0x53Ad0aF41dD7008e19B666A3fbe175B6215669F3;
    uint256 public constant PUBLIC_AMOUNT = 50_000_000 ether;

    address public constant TEAM = 0xEcd2369e23Fb21458aa41f7fb1cB1013913D97EA;
    uint256 public constant TEAM_AMOUNT = 150_000_000 ether;

    address public constant TREASURY =
        0xc674f8D0bBC54f8eB7e7c32d6b6E11dC07f01Af5;
    uint256 public constant TREASURY_AMOUNT = 200_000_000 ether;

    address public constant DEVELOPMENT =
        0x234567890abCdeF1234567890AbCDef123456788;
    uint256 public constant DEVELOPMENT_AMOUNT = 80_000_000 ether;

    address public constant MARKETING =
        0x34567890abCDEf1234567890aBCDEf1234567892;
    uint256 public constant MARKETING_AMOUNT = 90_000_000 ether;

    address public constant LIQUIDITY =
        0x4049C6d09D7c1C93D70181650279100E4D018D3D;
    uint256 public constant LIQUIDITY_AMOUNT = 180_000_000 ether;

    address public constant AIRDROP =
        0x137d220Fb68F637e98773E39aB74E466C773AC20;
    uint256 public constant AIRDROP_AMOUNT = 30_000_000 ether;

    address public constant ADVISOR =
        0xb1683022cDE0d8d69b4c458F52610f6Fd4e83D66;
    uint256 public constant ADVISOR_AMOUNT = 30_000_000 ether;

    constructor() ERC20("SuperMeme", "SPR") {
        _mint(SEED, SEED_AMOUNT);
        _mint(OPENS, OPENS_AMOUNT);
        _mint(KOL, KOL_AMOUNT);
        _mint(PUBLIC, PUBLIC_AMOUNT);
        _mint(TEAM, TEAM_AMOUNT);
        _mint(TREASURY, TREASURY_AMOUNT);
        _mint(DEVELOPMENT, DEVELOPMENT_AMOUNT);
        _mint(MARKETING, MARKETING_AMOUNT);
        _mint(LIQUIDITY, LIQUIDITY_AMOUNT);
        _mint(AIRDROP, AIRDROP_AMOUNT);
        _mint(ADVISOR, ADVISOR_AMOUNT);

        _mint(msg.sender, 10_000_000 ether);

        // require(
        //     totalSupply() == 1_000_000_000 * 10 ** decimals(),
        //     "SuperMeme: Invalid total supply"
        // );
    }
}
