// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./SuperMemeFactoryLib.sol";

contract SuperMemeFactory {
    using SuperMemeFactoryLib for *;

    address public revenueCollector = address(0x123);
    uint256 public createTokenRevenue = 0.00001 ether;
    address[] public tokenAddresses;

    function createToken(
        string memory _name,
        string memory _symbol,
        bool _devLocked,
        uint256 _amount,
        address _devAddress,
        uint256 _devLockDuration,
        uint256 _buyEth,
        uint256 _tokenType
    ) public payable returns (address) {
        address token = SuperMemeFactoryLib.createToken(
            _name,
            _symbol,
            _devLocked,
            _amount,
            _devAddress,
            _devLockDuration,
            _buyEth,
            _tokenType,
            revenueCollector,
            createTokenRevenue
        );

        tokenAddresses.push(token);
        return token;
    }
}
