pragma solidity 0.8.20;

import "../SuperMemeRefundableBondingCurve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/ISuperMemeRegistry.sol";

contract RefundableFactory is Ownable{

    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    ISuperMemeRegistry public superMemeRegistry;

    uint256 public createTokenRevenue = 0.00001 ether;
    address public revenueCollector;
    address[] public tokenAddresses;

    constructor(address _superMemeRegistry) Ownable(msg.sender) {
        superMemeRegistry = ISuperMemeRegistry(_superMemeRegistry);
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        address _devAddress,
        uint256 _buyEth
    ) public payable returns (address token) {
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        require(_devAddress == msg.sender, "Invalid dev address");

        (bool success, ) = revenueCollector.call{value: createTokenRevenue, gas: 50000}("");
        require(success, "Transfer failed");

        if (
            _amount == 0 &&
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
            _amount > 0 &&
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
        } else {
            revert("Invalid parameters");
        }
        tokenAddresses.push(token);
        superMemeRegistry.registerToken(token, _devAddress, _amount, false, 1);
        emit TokenCreated(token, _devAddress, _amount, false, 1);
    }

    function setCreateTokenRevenue(uint256 _createTokenRevenue) public onlyOwner {
        createTokenRevenue = _createTokenRevenue;
    }

    function setRevenueCollector(address _revenueCollector) public onlyOwner {
        revenueCollector = _revenueCollector;
    }

    function setSuperMemeRegistry(ISuperMemeRegistry _superMemeRegistry) public onlyOwner {
        superMemeRegistry = _superMemeRegistry;
    }
}
