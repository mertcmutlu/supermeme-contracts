pragma solidity 0.8.20;

import "./SuperMemeDegenBondingCurve.sol";
import "./SuperMemeRefundableBondingCurve.sol";

contract SuperMemeFactory {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 _tokenType
    );

    uint256 public createTokenRevenue = 0.00001 ether;
    address public revenueCollector = address(0x123);
    address[] public tokenAddresses;
    enum TokenType {
        DegenBondingCurve,
        SuperMemeRefundableBondingCurve
    }
    address private token;

    // crete a function to deploy the different tokens according to their types

    function createToken(
        string memory _name,
        string memory _symbol,
        bool _devLocked,
        uint256 _amount,
        address _devAdress,
        uint256 _devLockDuration,
        uint256 _buyEth,
        uint256 _tokenType
    ) public payable returns (address) {
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        require(
            _devLockDuration == 0 ||
                _devLockDuration == 1 weeks ||
                _devLockDuration == 2 weeks ||
                _devLockDuration == 3 weeks ||
                _devLockDuration == 4 weeks,
            "Invalid dev lock duration"
        );
        require(_devAdress == msg.sender, "Invalid dev address");
        payable(revenueCollector).transfer(createTokenRevenue);

        if (
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            _devLocked == false &&
            _amount == 0 &&
            _devLockDuration == 0 &&
            _buyEth == 0
        ) {
            console.log("inside no dev no buy if");
             token = address(
                new SuperMemeDegenBondingCurve(
                    _name,
                    _symbol,
                    _devLocked,
                    _amount,
                    _devAdress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
            tokenAddresses.push(address(token));
        } else if (
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            _devLocked == false &&
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
                    _devAdress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
            tokenAddresses.push(address(token));
        } else if(
            _tokenType == uint256(TokenType.DegenBondingCurve) &&
            _devLocked == true &&
            _amount > 0 &&
            _devLockDuration > 0 &&
            _buyEth > 0
        ){
            console.log("inside supermeme no dev no buy if");
            token = address(
                new SuperMemeDegenBondingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _devLocked,
                    _amount,
                    _devAdress,
                    revenueCollector,
                    _devLockDuration,
                    _buyEth
                )
            );
            tokenAddresses.push(address(token));
        
        } else if (
            _tokenType == uint256(TokenType.SuperMemeRefundableBondingCurve) &&
            _devLocked == false &&
            _amount == 0 &&
            _devLockDuration == 0 &&
            _buyEth == 0
        ) {
            token = address(
                new SuperMemeRefundableBondingCurve(
                    _name,
                    _symbol,
                    _amount,
                    _devAdress,
                    revenueCollector,
                    _buyEth
                )
            );
            tokenAddresses.push(address(token));
        } else if (
            _tokenType == uint256(TokenType.SuperMemeRefundableBondingCurve) &&
            _devLocked == false &&
            _amount > 0 &&
            _devLockDuration == 0 &&
            _buyEth > 0
        ) {
            token = address(
                new SuperMemeRefundableBondingCurve{value: _buyEth}(
                    _name,
                    _symbol,
                    _amount,
                    _devAdress,
                    revenueCollector,
                    _buyEth
                )
            );
            tokenAddresses.push(address(token));
        } 
        
        emit TokenCreated(
            address(token),
            _devAdress,
            _amount,
            _devLocked,
            _tokenType
        );
        return address(token);
    }
        function receive() external payable {}
}

// string memory _name,
// string memory _symbol,
// bool _devLocked,
// uint256 _amount,
// address _devAdress,
// address _revenueCollector,
// uint256 _devLockDuration,
// uint256 _buyEth
