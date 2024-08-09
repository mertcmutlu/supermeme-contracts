// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "forge-std/console.sol";
import "./Interfaces/IUniswapV2Pair.sol";


contract SuperMemeRefundableBondingCurve is ERC20 {


    uint256 public constant MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public MAXIMUM_TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;
    uint256 public constant buyPointScale = 10000;

    uint256 public scaledSupply;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public totalRefundedTokens;
    uint256 public totalEtherCollected;

    uint256 public tradeTax = 1000;
    uint256 public tradeTaxDivisor = 100000;
    uint256 public sendDexRevenue = 0.15 ether;

    bool public bondingCurveCompleted;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    event SentToDex(uint256 ethAmount, uint256 tokenAmount, uint256 timestamp);
    event Price(uint256 indexed _price, uint256 indexed _totalSupply, address indexed _tokenAddress,uint256 _amount);

    event tokensBought(
        uint256 indexed amount,
        uint256 cost,
        address indexed tokenAddress,
        address indexed buyer,
        uint256 totalSupply
    );
    event tokensRefunded(
        uint256 indexed amount, 
        uint256 refund,
        address indexed _tokenAddress,
        address indexed _refunder,
        uint256 _price
    );

    uint256 public buyCount;
    mapping(uint256 => address) public buyIndex;
    mapping(uint256 => uint256) public buyCost;
    mapping(uint256 => bool) public isRefund;
    mapping(uint256 => uint256) public cumulativeEthCollected;
    mapping(address => uint256[]) public userBuysPoints;
    mapping(address => uint256[]) public userBuyPointsEthPaid;
    mapping(address => uint256[]) public userBuyPointPercentages;
    mapping(address => uint256) public totalEthPaidUser;
    mapping(address => uint256) public userBalanceScaled;

    address public devAddress;
    uint256 public devLockDuration;
    address public factoryContract;



    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        address _devAdress,
        address _revenueCollector,
        uint256 _ethBuy
    ) public payable ERC20(_name, _symbol) {
        factoryContract = msg.sender;
        revenueCollector = _revenueCollector;
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x5633464856F58Dfa9a358AfAf49841FEE990e30b
        );
        uniswapV2Router = _uniswapV2Router;
        devAddress = _devAdress;

        if (_amount > 0) {
            console.log("amount is greater than 0, trying to buy tokens");
            buyTokens(_amount, 100, _ethBuy);
        }
    }
    function buyTokens(uint256 _amount, uint256 _slippage,uint256 _ethBuy) public payable {
        require(
            !bondingCurveCompleted,
            "Bonding curve completed, no buys allowed"
        );

        require(_amount > 0, "Amount must be greater than 0");
        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;

        uint256 totalCost = cost + tax;
   

        uint256 slippageAmount = (totalCost * _slippage) / 10000;
        require(
            _ethBuy >= totalCost - slippageAmount && _ethBuy <= totalCost + slippageAmount,
            "Insufficient or excess Ether sent, exceeds slippage tolerance"
        );
        require(msg.value >= cost + tax, "Insufficient Ether sent");
        payTax(tax);
        uint256 excessEth = (_ethBuy - totalCost > 0) ? _ethBuy - totalCost : 0;
        address buyer = (msg.sender == factoryContract)
            ? devAddress
            : msg.sender;
        console.log("before excess eth");
        if (excessEth > 0) {
            payable(buyer).transfer(excessEth);
        }
        console.log("after excess eth");
        buyIndex[buyCount] = buyer;
        buyCost[buyCount] = cost;
        userBuysPoints[buyer].push(buyCount);
        userBuyPointsEthPaid[buyer].push(msg.value - tax);
        buyCount += 1;

        totalEthPaidUser[buyer] += _ethBuy -tax;
        totalEtherCollected += _ethBuy - tax - excessEth;
        cumulativeEthCollected[buyCount] += _ethBuy - tax - excessEth;
        calculateUserBuyPointPercentages(buyer);
        userBalanceScaled[buyer] += _amount;
        scaledSupply += _amount;
        _mint(buyer, _amount * 10 ** 18);
        uint256 totalSup = totalSupply();
        uint256 price = calculateCost(1);
            emit tokensBought(
                _amount,
                cost,
                address(this),
                buyer,
                totalSup
            );
            emit Price(price, totalSup, address(this),_amount);
        
        if (scaledSupply >= MAX_SALE_SUPPLY) {
            bondingCurveCompleted = true;
        }

        console.log("function completed");
        if (bondingCurveCompleted) {
            sendToDex();
        }
    }
    function calculateUserBuyPointPercentages(address _buyer) internal {
        uint256[] memory userBuyPoints = userBuysPoints[msg.sender];
        for (uint256 i = 0; i < userBuyPoints.length; i++) {
            uint256 buyPoint = userBuyPoints[i];
            uint256 cost = buyCost[buyPoint];
            uint256 percentage = (cost * buyPointScale) /
            totalEthPaidUser[_buyer];
            userBuyPointPercentages[_buyer].push(percentage);
        }
    }

    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply + amount;
        uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        return cost;
    }
    function payTax(uint256 _tax) internal {
        payable(revenueCollector).transfer(_tax);
        totalRevenueCollected += _tax;
    }
        function sendToDex() public payable {
        require(bondingCurveCompleted, "Bonding curve not completed");
        payTax(sendDexRevenue);
        totalEtherCollected -= sendDexRevenue;
        uint256 _ethAmount = totalEtherCollected;
        uint256 _tokenAmount = liquidityThreshold;
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        emit SentToDex(_ethAmount, _tokenAmount, block.timestamp);
    }
}