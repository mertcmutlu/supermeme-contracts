pragma solidity 0.8.20;

import "../SuperMemeDegenBondingCurve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "../Interfaces/ISuperMemeRegistry.sol";

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

contract DegenFactory  is Ownable  {

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
        bool _devLocked,
        uint256 _amount,
        address _devAddress,
        uint256 _devLockDuration,
        uint256 _buyEth
    ) public payable returns (address token) {

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

        (bool success, ) = revenueCollector.call{value: createTokenRevenue, gas: 50000}("");
        require(success, "Transfer failed");

        if (
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
            _devLocked &&
            _amount > 0 &&
            _buyEth > 0 &&
            _devLockDuration > 0
        ) 
        {  
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
            !_devLocked &&
            _amount > 0 &&
            _buyEth > 0 &&
            _devLockDuration == 0
        ) 
        {  
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
        } 
        else {
            revert("Invalid parameters");
        }
        ("Token created: ", token);
        superMemeRegistry.registerToken(token,_devAddress,_amount,_devLocked,0);
        tokenAddresses.push(token);
        emit TokenCreated(token, _devAddress, _amount, _devLocked, 0);
        return token;
    }

    function setRevenueCollector(address _revenueCollector) public onlyOwner {
        revenueCollector = _revenueCollector;
    }
    function setCreateTokenRevenue(uint256 _createTokenRevenue) public onlyOwner {
        createTokenRevenue = _createTokenRevenue;
    }

    function setSuperMemeRegistry(address _superMemeRegistry) public onlyOwner {
        superMemeRegistry = ISuperMemeRegistry(_superMemeRegistry);
    }
}