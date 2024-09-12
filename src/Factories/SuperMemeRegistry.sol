pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";


contract SuperMemeRegistry is Ownable {
    event TokenCreated(
        address indexed tokenAddress,
        address indexed devAddress,
        uint256 amount,
        bool devLocked,
        uint256 tokenType
    );

    address[] public tokenAddresses;
    address public refundableFactory;
    address public degenFactory;
    address public lockingCurveFactory;

    constructor() Ownable(msg.sender) {
        refundableFactory = address(0);
        degenFactory = address(0);
        lockingCurveFactory = address(0);
    }

    function registerToken(
        address _tokenAddress,
        address _devAddress,
        uint256 _amount,
        bool _devLocked,
        uint256 _tokenType
    ) public onlyFactory {
        tokenAddresses.push(_tokenAddress);
        emit TokenCreated(_tokenAddress, _devAddress, _amount, _devLocked, _tokenType);
    }

    modifier onlyFactory() {
        require(
            msg.sender == refundableFactory ||
                msg.sender == degenFactory ||
                msg.sender == lockingCurveFactory,
            "Only factory can call this function"
        );
        _;
    }

    function setRefundableFactory(address _refundableFactory) public onlyOwner {
        refundableFactory = _refundableFactory;
    }

    function setDegenFactory(address _degenFactory) public onlyOwner {
        degenFactory = _degenFactory;
    }

    function setLockingCurveFactory(address _lockingCurveFactory) public onlyOwner {
        lockingCurveFactory = _lockingCurveFactory;
    }
}