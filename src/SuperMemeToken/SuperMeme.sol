// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract SuperMeme is ERC20 {
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

        require(
            totalSupply() == 1_000_000_000 * 10 ** decimals(),
            "SuperMeme: Invalid total supply"
        );
    }
}
