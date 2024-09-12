// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../SuperMemeDegenBondingCurve.sol";
import "../SuperMemeRefundableBondingCurve.sol";
import "../SuperMemeLockingCurve.sol";

library SuperMemeFactoryLib {

    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    enum TokenType {
        DegenBondingCurve,
        SuperMemeRefundableBondingCurve,
        SuperMemeLockingCurve
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        bool _devLocked,
        uint256 _amount,
        address _devAddress,
        uint256 _devLockDuration,
        uint256 _buyEth,
        uint256 _tokenType,
        address revenueCollector,
        uint256 createTokenRevenue
    ) internal returns (address token) {
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        require(
            _devLockDuration == 0 ||
                _devLockDuration == 1 weeks ||
                _devLockDuration == 2 weeks ||
                _devLockDuration == 3 weeks ||
                _devLockDuration == 4 weeks,
            "Invalid dev lock duration"
        );
        require(_devAddress == msg.sender, "Invalid dev address");

        payable(revenueCollector).transfer(createTokenRevenue);

        if (
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            !_devLocked &&
            _amount == 0 &&
            _devLockDuration == 0 &&
            _buyEth == 0
        ) {
            token = address(
                new SuperMemeDegenBondingCurve(
                    _name,
                    _symbol,
                    _devLocked,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
        } else if (
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            !_devLocked &&
            _amount > 0 &&
            _devLockDuration == 0 &&
            _buyEth > 0
        ) {
            token = address(
                new SuperMemeDegenBondingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _devLocked,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
        } else if(
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            _devLocked &&
            _amount > 0 &&
            _devLockDuration > 0 &&
            _buyEth > 0
        ){
            token = address(
                new SuperMemeDegenBondingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _devLocked,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
        } else if (
            _tokenType == uint256(TokenType.SuperMemeRefundableBondingCurve) &&
            !_devLocked &&
            _amount == 0 &&
            _devLockDuration == 0 &&
            _buyEth == 0
        ) {
            token = address(
                new SuperMemeRefundableBondingCurve(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth
                )
            );
        } else if (
            _tokenType == uint256(TokenType.SuperMemeRefundableBondingCurve) &&
            !_devLocked &&
            _amount > 0 &&
            _devLockDuration == 0 &&
            _buyEth > 0
        ) {
            token = address(
                new SuperMemeRefundableBondingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth
                )
            );
        } else if (
            _tokenType == uint256(TokenType.SuperMemeLockingCurve) &&
            !_devLocked &&
            _amount == 0 &&
            _devLockDuration == 0 &&
            _buyEth == 0
        ) {
            token = address(
                new SuperMemeLockingCurve(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth,
                    0
                )
            );
        } else if (
            _tokenType == uint256(TokenType.SuperMemeLockingCurve) &&
            !_devLocked &&
            _amount > 0 &&
            _devLockDuration == 0 &&
            _buyEth > 0
        ) {
            token = address(
                new SuperMemeLockingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _amount,
                    _devAddress,
                    revenueCollector,
                    _buyEth,
                    0
                )
            );
        } else {
            revert("Invalid token creation parameters");
        }
        emit TokenCreated(
            token,
            _devAddress,
            _amount,
            _devLocked,
            _tokenType
        );
    }
}
