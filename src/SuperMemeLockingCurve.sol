// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "forge-std/console.sol";

contract SuperMemeLockingCurve is ERC20 {
    event SentToDex(uint256 ethAmount, uint256 tokenAmount, uint256 timestamp);
    event Price(
        uint256 indexed price,
        uint256 indexed totalSupply,
        address indexed tokenAddress,
        uint256 amount
    );
    event tokensBought(
        uint256 indexed amount,
        uint256 cost,
        address indexed tokenAddress,
        address indexed buyer,
        uint256 totalSupply
    );
    event tokensSold(
        uint256 indexed amount,
        uint256 refund,
        address indexed tokenAddress,
        address indexed seller,
        uint256 totalSupply
    );

    uint256 public MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
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
    bool public scaledBondingCurveCompleted;
    bool public dexStage;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public sendDexRevenue = 0.15 ether;

    uint256 public constant tMax = 3 days;
    mapping(address => uint256) public lockTime;
    uint256 public previousLockTime;
    uint256 public firstLockTime;
    uint256 public allLocksExpire;

    uint256 public constant scaledBondingCurveThreshold = 750_000_000;
    uint256 public constant voterCut = 0.005 ether;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    address public factoryContract;
    address[] public sendToDexVoters;

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
        require(checkRemainingLockTime(msg.sender) == 0, "Already Bought In");
        require(_amount > 0, "0 amount");
        require(!bondingCurveCompleted || !dexStage, "Curve done");

        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        uint256 totalCost = cost + tax;
        uint256 slippageAmount = (totalCost * _slippage) / 10000;
        uint256 minimumCost = totalCost - slippageAmount;

        require(
            _buyEth >= minimumCost && _buyEth <= totalCost + slippageAmount,
            "Slippage"
        );
        payTax(tax);
        uint256 excessEth = (_buyEth - totalCost > 0) ? _buyEth - totalCost : 0;
        require(scaledSupply + _amount <= MAX_SALE_SUPPLY, "Max supply");

        totalEtherCollected += cost;
        scaledSupply += _amount;

        if (scaledSupply >= MAX_SALE_SUPPLY) {
            bondingCurveCompleted = true;
        } else if (scaledSupply >= scaledBondingCurveThreshold) {
            scaledBondingCurveCompleted = true;
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
        calculateLockingDuration(buyer);
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
        require(
            bondingCurveCompleted || scaledBondingCurveCompleted,
            "Curve not done"
        );
        if (sendToDexVoters.length == 0) {
            require(balanceOf(msg.sender) >= 1000000 * 10 ** 18, "Low tokens");
            sendToDexVoters.push(msg.sender);
            return;
        } else {
            bool alreadyVoted = false;
            for (uint256 i = 0; i < sendToDexVoters.length; i++) {
                if (sendToDexVoters[i] == msg.sender) {
                    alreadyVoted = true;
                    return;
                }
            }
            if (!alreadyVoted) {
                require(
                    balanceOf(msg.sender) >= 1000000 * 10 ** 18,
                    "Low tokens"
                );
                sendToDexVoters.push(msg.sender);
            }
        }
        if (sendToDexVoters.length >= 5) {
            for (uint256 i = 0; i < sendToDexVoters.length; i++) {
                payable(sendToDexVoters[i]).transfer(voterCut);
            }
            for (uint256 i = 0; i < sendToDexVoters.length; i++) {
                sendToDexVoters.pop();
            }

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
            dexStage = true;
            emit SentToDex(_ethAmount, _tokenAmount, block.timestamp);
        }
    }

    function sellTokens(uint256 _amount, uint256 _minimumEthRequired) public {
        require(_amount > 0, "0 amount");
        require(!bondingCurveCompleted || !dexStage, "Curve done");
        console.log("inside sell");
        uint256 refund = calculateRefund(_amount);
        uint256 tax = (refund * tradeTax) / tradeTaxDivisor;
        uint256 netRefund = refund - tax;

        require(address(this).balance >= netRefund, "Low ETH");
        require(balanceOf(msg.sender) >= _amount * 10 ** 18, "Low tokens");
        require(netRefund >= _minimumEthRequired, "Low refund");
        payTax(tax);
        console.log("after tax");
        _burn(msg.sender, _amount * 10 ** 18);
        console.log("after burn");
        totalEtherCollected -= netRefund + tax;
        scaledSupply -= _amount;

        payable(msg.sender).transfer(netRefund);
        if (scaledSupply < scaledBondingCurveThreshold) {
            scaledBondingCurveCompleted = false;
            for (uint256 i = 0; i < sendToDexVoters.length; i++) {
                sendToDexVoters.pop();
            }
        }
        uint256 totalSup = totalSupply();
        uint256 lastPrice = calculateCost(1);
        emit tokensSold(_amount, refund, address(this), msg.sender, totalSup);
        emit Price(lastPrice, totalSup, address(this), _amount);
    }

    function calculateRefund(uint256 _amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply - _amount;
        uint256 refund = ((((A * ((currentSupply ** 3) - (newSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        return refund;
    }
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        console.log("from", from);
        console.log("to", to);

        if (
            (from != address(this) && from != address(0)) &&
            to == address(this) &&
            !dexStage
        ) {
            revert("No transfer new");
        }
        console.log("inside update");
        if (dexStage) {
            super._update(from, to, value);
        } else {
            if (
                from == address(this) || from == address(0) || to == address(0)
            ) {
                if (checkRemainingLockTime(from) == 0) {
                    super._update(from, to, value);
                } else {
                    revert("No transfer");
                }
            } else {
                revert("No transfer");
            }
        }
    }
    function setUniRouter(address _uniswapV2Router) public {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function remainingTokens() public view returns (uint256) {
        return MAX_SALE_SUPPLY - scaledSupply;
    }

    function calculateLockingDuration(
        address _address
    ) public returns (uint256) {
        if (allLocksExpire != 0 && allLocksExpire < block.timestamp) {
            lockTime[_address] = 0;
            return lockTime[_address];
        }
        console.log("previousLockTime inside contract", previousLockTime);
        if (previousLockTime == 0) {
            previousLockTime = tMax;
            lockTime[_address] = block.timestamp + tMax;
            firstLockTime = block.timestamp;
            allLocksExpire = block.timestamp + tMax;
            return lockTime[_address];
        } else {
            uint256 timePassed = block.timestamp - firstLockTime;
            if (timePassed > previousLockTime) {
                previousLockTime = 0;
            } else {
                previousLockTime -= timePassed;
            }
            uint256 newLockTime = previousLockTime;
            uint256 scaledReduction = (scaledSupply * previousLockTime) /
                MAX_SALE_SUPPLY / 4;
            if (scaledReduction > previousLockTime) {
                newLockTime = 0;
            } else {
                newLockTime -= scaledReduction;
            }
            console.log("newLockTime inside contract", newLockTime);
            if (firstLockTime + timePassed > block.timestamp + newLockTime) {
                lockTime[_address] = 0;
                return lockTime[_address];
            }

            lockTime[_address] = block.timestamp + newLockTime;
            return lockTime[_address];
        }
    }
    function checkRemainingLockTime(
        address _address
    ) public view returns (uint256) {
        if (allLocksExpire != 0 && allLocksExpire < block.timestamp) {
            return 0;
        }
        if (lockTime[_address] != 0) {
            return (lockTime[_address] - block.timestamp < 0) ? 0 : lockTime[_address] - block.timestamp;
        }
    }
}
