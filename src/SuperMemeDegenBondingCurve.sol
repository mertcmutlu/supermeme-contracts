pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "forge-std/console.sol";
import "./Interfaces/IUniswapV2Pair.sol";

contract SuperMemeDegenBondingCurve is ERC20 {
    event SentToDex(uint256 ethAmount, uint256 tokenAmount, uint256 timestamp);
    event Price(
        uint256 indexed _price,
        uint256 indexed _totalSupply,
        address indexed _tokenAddress,
        uint256 _amount
    );
    event tokensBought(
        uint256 indexed _amount,
        uint256 _cost,
        address indexed _tokenAddress,
        address indexed _buyer,
        uint256 _totalSupply
    );
    event tokensSold(
        uint256 indexed _amount,
        uint256 _refund,
        address indexed _tokenAddress,
        address indexed _seller,
        uint256 _totalSupply
    );

    uint256 public constant MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;

    uint256 private constant tradeTax = 1000;
    uint256 private constant tradeTaxDivisor = 100000;

    uint256 public totalEtherCollected;
    uint256 public scaledSupply;

    address public devAddress;
    bool public devLocked;
    uint256 public devLockTime;

    bool public bondingCurveCompleted;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public sendDexRevenue = 0.15 ether;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    address public factoryContract;

    constructor(
        string memory _name,
        string memory _symbol,
        bool _devLocked,
        uint256 _amount,
        address _devAdress,
        address _revenueCollector,
        uint256 _devLockDuration,
        uint256 _buyEth
    ) public payable ERC20(_name, _symbol) {
        factoryContract = msg.sender;
        revenueCollector = _revenueCollector;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x5633464856F58Dfa9a358AfAf49841FEE990e30b
        );
        uniswapV2Router = _uniswapV2Router;
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;
        devAddress = _devAdress;
        devLocked = _devLocked;
        devLockTime = block.timestamp + _devLockDuration;
        if (_amount > 0) {
            buyTokens(_amount, 100, _buyEth);
        }
    }
    function buyTokens(
        uint256 _amount,
        uint256 _slippage,
        uint256 _buyEth
    ) public payable {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            bondingCurveCompleted == false,
            "Bonding curve completed, no more tokens can be bought"
        );
        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        uint256 totalCost = cost + tax;
        uint256 slippageAmount = (totalCost * _slippage) / 10000;
        uint256 minimumCost = totalCost - slippageAmount;
        require(
            _buyEth >= minimumCost && _buyEth <= totalCost + slippageAmount,
            "Insufficient or excess Ether sent, exceeds slippage tolerance"
        );
        //payTax(tax);
        // check if totalcost is greater than the amount of ether sent
        uint256 excessEth = (_buyEth - totalCost > 0) ? _buyEth - totalCost : 0;
        require(
            scaledSupply + _amount <= MAX_SALE_SUPPLY,
            "Exceeds maximum supply"
        );
        totalEtherCollected += totalCost - tax -excessEth;
        scaledSupply += _amount;

        if (scaledSupply >= MAX_SALE_SUPPLY) {
            bondingCurveCompleted = true;
        }
        address buyer = (msg.sender == factoryContract)
            ? devAddress
            : msg.sender;

        if (excessEth > 0) {
            payable(buyer).transfer(excessEth);
        }
        _mint(buyer, _amount * 10 ** 18);
        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);
        emit tokensBought(_amount, cost, address(this), buyer, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);


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
