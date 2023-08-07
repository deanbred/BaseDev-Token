// SPDX-License-Identifier: AGPL-3.0-only
/*
    BaseDev DEX
    Website: https://basedev.tech/
    Discord: 
    X: @basedev777
*/
pragma solidity = 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISwapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountCANTOMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountCANTO);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function pairFor(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface ISwapV2Factory {
    function allPairsLength() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function pairCodeHash() external pure returns (bytes32);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address);

    function getInitializable()
        external
        view
        returns (
            address token0,
            address token1,
            bool stable
        );

    function protocolFeesShare() external view returns (uint256);

    function protocolFeesRecipient() external view returns (address);

    function tradingFees(address pair, address to)
        external
        view
        returns (uint256);

    function isPaused() external view returns (bool);
}

interface ISwapV2Pair {
    function factory() external view returns (address);

    function fees() external view returns (address);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function current(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);

    function balanceOf(address) external view returns (uint256);

    //LP token pricing
    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory);

    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256);

    function claimFeesFor(address account)
        external
        returns (uint256 claimed0, uint256 claimed1);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function claimableFeesFor(address account)
        external
        returns (uint256 claimed0, uint256 claimed1);

    function claimableFees()
        external
        returns (uint256 claimed0, uint256 claimed1);
}

interface ILiquidityManageable {
    function setLiquidityManagementPhase(bool _isManagingLiquidity) external;

    function isLiquidityManager(address _addr) external returns (bool);

    function isLiquidityManagementPhase() external returns (bool);
}

interface IFeeDiscountOracle {
    function buyFeeDiscountFor(address account, uint256 totalFeeAmount)
        external
        view
        returns (uint256 discountAmount);

    function sellFeeDiscountFor(address account, uint256 totalFeeAmount)
        external
        view
        returns (uint256 discountAmount);
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract BaseDev is ERC20, Ownable, ILiquidityManageable {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public constant MAX_FEE = 1000;

    uint256 public burnBuyFee;
    uint256 public farmsBuyFee;
    uint256 public stakingBuyFee;
    uint256 public treasuryBuyFee;
    uint256 public totalBuyFee;

    uint256 public burnSellFee;
    uint256 public farmsSellFee;
    uint256 public stakingSellFee;
    uint256 public treasurySellFee;
    uint256 public totalSellFee;

    address public farmsFeeRecipient;
    address public stakingFeeRecipient;
    address public treasuryFeeRecipient;

    bool public tradingEnabled;
    uint256 public tradingEnabledTimestamp = 0;

    ISwapV2Router01 public swapFeesRouter;
    IFeeDiscountOracle public feeDiscountOracle;
    address public swapPairToken;
    bool public swappingFeesEnabled;
    bool public isSwappingFees;
    uint256 public swapFeesAtAmount;
    uint256 public maxSwapFeesAmount;
    uint256 public maxWalletAmount;

    uint256 public sniperBuyBaseFee = 100;
    uint256 public sniperBuyFeeDecayPeriod = 10 minutes;
    uint256 public sniperBuyFeeBurnShare = 0;
    bool public sniperBuyFeeEnabled = true;

    uint256 public sniperSellBaseFee = 100;
    uint256 public sniperSellFeeDecayPeriod = 10 minutes;
    uint256 public sniperSellFeeBurnShare = 0;
    bool public sniperSellFeeEnabled = true;

    bool public pairAutoDetectionEnabled;
    bool public indirectSwapFeeEnabled;
    bool public maxWalletEnabled;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isLiquidityManager;
    mapping(address => bool) public isWhitelistedFactory;
    mapping(address => bool) public isBot;

    bool internal _isLiquidityManagementPhase;
    uint256 internal _currentCacheVersion;
    mapping(address => bool) internal _isLpPair;
    mapping(uint256 => mapping(address => bool))
        internal _isCachedAutodetectedLpPair;
    mapping(address => bool) internal _isExcludedFromMaxWallet;

    event BuyFeeUpdated(uint256 _fee, uint256 _previousFee);
    event SellFeeUpdated(uint256 _fee, uint256 _previousFee);
    event LpPairAdded(address _pair);
    event LpPairRemoved(address _pair);
    event AddressExcludedFromFees(address _address);
    event AddressIncludedInFees(address _address);
    event WhitelistedFactoryAdded(address _factory);
    event WhitelistedFactoryRemoved(address _factory);

    error TradingNotEnabled();
    error TradingAlreadyEnabled();
    error SniperBotDetected();
    error MaxWalletReached();
    error TimestampIsInThePast();
    error FeeTooHigh();
    error InvalidFeeRecipient();
    error NotLiquidityManager();
    error TransferFailed();
    error ArrayLengthMismatch();

    constructor(
        address _router,
        address _farms,
        address _staking,
        address _treasury
    ) ERC20("BaseDev", "BASEDEV") {
        ISwapV2Router01 router = ISwapV2Router01(_router);
        ISwapV2Factory factory = ISwapV2Factory(router.factory());
        swapPairToken = router.WETH();

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[DEAD] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[DEAD] = true;

        burnBuyFee = 0;
        farmsBuyFee = 111;
        stakingBuyFee = 111;
        treasuryBuyFee = 111;
        setBuyFees(burnBuyFee, farmsBuyFee, stakingBuyFee, treasuryBuyFee);

        burnSellFee = 0;
        farmsSellFee = 111;
        stakingSellFee = 111;
        treasurySellFee = 111;
        setSellFees(burnSellFee, farmsSellFee, stakingSellFee, treasurySellFee);

        farmsFeeRecipient = address(_farms);
        stakingFeeRecipient = address(_staking);
        treasuryFeeRecipient = address(_treasury);

        isExcludedFromFee[farmsFeeRecipient] = true;
        isExcludedFromFee[stakingFeeRecipient] = true;
        isExcludedFromFee[treasuryFeeRecipient] = true;

        isLiquidityManager[address(router)] = true;
        isWhitelistedFactory[address(factory)] = true;

        address pair = factory.createPair(address(this), swapPairToken);
        address feesVault = ISwapV2Pair(pair).fees();
        _isExcludedFromMaxWallet[feesVault] = true;
        isExcludedFromFee[feesVault] = true;
        _isLpPair[pair] = true;
        maxWalletEnabled = true;

        _mint(owner(), 7000000000 * 10 ** decimals());
        _mint(farmsFeeRecipient, 222222222 * 10 ** decimals());
        _mint(stakingFeeRecipient, 222222222 * 10 ** decimals());
        _mint(treasuryFeeRecipient, 333333333 * 10 ** decimals());

        swapFeesRouter = router;
        swapFeesAtAmount = (totalSupply() * 3) / 1e5;
        maxSwapFeesAmount = (totalSupply() * 4) / 1e5;
        maxWalletAmount = (totalSupply() * 49) / 1e4;
    }

    modifier onlyLiquidityManager() {
        if (!isLiquidityManager[msg.sender]) {
            revert NotLiquidityManager();
        }
        _;
    }

    function isLpPair(address _pair) public returns (bool isPair) {
        if (_isLpPair[_pair]) {
            return true;
        }

        if (!pairAutoDetectionEnabled) {
            return false;
        }

        if (_isCachedAutodetectedLpPair[_currentCacheVersion][_pair]) {
            return true;
        }

        if (_pair.code.length == 0) {
            return false;
        }

        (bool success, bytes memory data) = _pair.staticcall(
            abi.encodeWithSignature("factory()")
        );
        if (!success) return false;
        address factory = abi.decode(data, (address));
        if (factory == address(0)) return false;

        bool isVerifiedPair = isWhitelistedFactory[factory] &&
            ISwapV2Factory(factory).isPair(_pair);

        (success, data) = _pair.staticcall(abi.encodeWithSignature("token0()"));
        if (!success) return false;
        address token0 = abi.decode(data, (address));
        if (token0 == address(this)) {
            if (isVerifiedPair) {
                _isCachedAutodetectedLpPair[_currentCacheVersion][
                    _pair
                ] = true;
            }

            return true;
        }

        (success, data) = _pair.staticcall(abi.encodeWithSignature("token1()"));
        if (!success) return false;
        address token1 = abi.decode(data, (address));
        if (token1 == address(this)) {
            if (isVerifiedPair) {
                _isCachedAutodetectedLpPair[_currentCacheVersion][
                    _pair
                ] = true;
            }

            return true;
        }

        return false;
    }

    function _shouldTakeTransferTax(
        address sender,
        address recipient
    ) internal returns (bool) {
        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return false;
        }

        return
            !_isLiquidityManagementPhase &&
            (isLpPair(sender) || isLpPair(recipient));
    }

    function sniperBuyFee() public view returns (uint256) {
        if (!sniperBuyFeeEnabled) {
            return 0;
        }

        uint256 timeSinceLaunch = block.timestamp - tradingEnabledTimestamp;

        if (timeSinceLaunch >= sniperBuyFeeDecayPeriod) {
            return 0;
        }

        return
            sniperBuyBaseFee -
            (sniperBuyBaseFee * timeSinceLaunch) /
            sniperBuyFeeDecayPeriod;
    }

    function sniperSellFee() public view returns (uint256) {
        if (!sniperSellFeeEnabled) {
            return 0;
        }

        uint256 timeSinceLaunch = block.timestamp - tradingEnabledTimestamp;

        if (timeSinceLaunch >= sniperSellFeeDecayPeriod) {
            return 0;
        }

        return
            sniperSellBaseFee -
            (sniperSellBaseFee * timeSinceLaunch) /
            sniperSellFeeDecayPeriod;
    }

    function buyFeeDiscountFor(
        address account,
        uint256 totalFeeAmount
    ) public view returns (uint256) {
        if (address(feeDiscountOracle) == address(0)) return 0;
        return feeDiscountOracle.buyFeeDiscountFor(account, totalFeeAmount);
    }

    function sellFeeDiscountFor(
        address account,
        uint256 totalFeeAmount
    ) public view returns (uint256) {
        if (address(feeDiscountOracle) == address(0)) return 0;
        return feeDiscountOracle.sellFeeDiscountFor(account, totalFeeAmount);
    }

    function _takeBuyFee(
        address sender,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        if (totalBuyFee == 0) return 0;

        uint256 totalFeeAmount = (amount * totalBuyFee) / FEE_DENOMINATOR;
        uint256 feeDiscountAmount = buyFeeDiscountFor(user, totalFeeAmount);

        totalFeeAmount -= feeDiscountAmount;
        if (totalFeeAmount == 0) return 0;

        uint256 burnFeeAmount = (totalFeeAmount * burnBuyFee) / totalBuyFee;
        uint256 farmsFeeAmount = (totalFeeAmount * farmsBuyFee) / totalBuyFee;
        uint256 stakingFeeAmount = (totalFeeAmount * stakingBuyFee) /
            totalBuyFee;
        uint256 treasuryFeeAmount = totalFeeAmount -
            burnFeeAmount -
            farmsFeeAmount -
            stakingFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (farmsFeeAmount > 0)
            super._transfer(sender, farmsFeeRecipient, farmsFeeAmount);

        if (stakingFeeAmount > 0)
            super._transfer(sender, stakingFeeRecipient, stakingFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSellFee(
        address sender,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        if (totalSellFee == 0) return 0;

        uint256 totalFeeAmount = (amount * totalSellFee) / FEE_DENOMINATOR;
        uint256 feeDiscountAmount = sellFeeDiscountFor(user, totalFeeAmount);

        totalFeeAmount -= feeDiscountAmount;
        if (totalFeeAmount == 0) return 0;

        uint256 burnFeeAmount = (totalFeeAmount * burnSellFee) / totalSellFee;
        uint256 farmsFeeAmount = (totalFeeAmount * farmsSellFee) / totalSellFee;
        uint256 stakingFeeAmount = (totalFeeAmount * stakingSellFee) /
            totalSellFee;
        uint256 treasuryFeeAmount = totalFeeAmount -
            burnFeeAmount -
            farmsFeeAmount -
            stakingFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (farmsFeeAmount > 0)
            super._transfer(sender, farmsFeeRecipient, farmsFeeAmount);

        if (stakingFeeAmount > 0)
            super._transfer(sender, stakingFeeRecipient, stakingFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSniperBuyFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalFeeAmount = (amount * sniperBuyFee()) / FEE_DENOMINATOR;
        uint256 burnFeeAmount = (totalFeeAmount * sniperBuyFeeBurnShare) /
            FEE_DENOMINATOR;
        uint256 treasuryFeeAmount = totalFeeAmount - burnFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSniperSellFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalFeeAmount = (amount * sniperSellFee()) / FEE_DENOMINATOR;
        uint256 burnFeeAmount = (totalFeeAmount * sniperSellFeeBurnShare) /
            FEE_DENOMINATOR;
        uint256 treasuryFeeAmount = totalFeeAmount - burnFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (
            !(tradingEnabled && tradingEnabledTimestamp <= block.timestamp) &&
            !isExcludedFromFee[sender] &&
            !isExcludedFromFee[recipient]
        ) {
            revert TradingNotEnabled();
        }

        if (isBot[sender] || isBot[recipient]) revert SniperBotDetected();

        if (
            maxWalletEnabled &&
            !isExcludedFromMaxWallet(recipient) &&
            balanceOf(recipient) + amount > maxWalletAmount
        ) revert MaxWalletReached();

        bool takeFee = !isSwappingFees &&
            _shouldTakeTransferTax(sender, recipient);
        bool isBuy = isLpPair(sender);
        bool isSell = isLpPair(recipient);
        bool isIndirectSwap = (_isLpPair[sender] ||
            _isCachedAutodetectedLpPair[_currentCacheVersion][sender]) &&
            (_isLpPair[recipient] ||
                _isCachedAutodetectedLpPair[_currentCacheVersion][recipient]);
        takeFee = takeFee && (indirectSwapFeeEnabled || !isIndirectSwap);

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwapFees = contractTokenBalance >= swapFeesAtAmount;
        bool isEOATransfer = sender.code.length == 0 &&
            recipient.code.length == 0;

        if (
            canSwapFees &&
            swappingFeesEnabled &&
            !isSwappingFees &&
            !_isLiquidityManagementPhase &&
            !isIndirectSwap &&
            (isSell || isEOATransfer) &&
            !isExcludedFromFee[sender] &&
            !isExcludedFromFee[recipient]
        ) {
            isSwappingFees = true;
            _swapFees();
            isSwappingFees = false;
        }

        uint256 totalFeeAmount;
        if (takeFee) {
            if (isSell) {
                totalFeeAmount = _takeSellFee(sender, sender, amount);
                totalFeeAmount += _takeSniperSellFee(sender, amount);
            } else if (isBuy) {
                totalFeeAmount = _takeBuyFee(sender, recipient, amount);
                totalFeeAmount += _takeSniperBuyFee(sender, amount);
            }
        }

        super._transfer(sender, recipient, amount - totalFeeAmount);
    }

    function _swapFees() internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = contractTokenBalance > maxSwapFeesAmount
            ? maxSwapFeesAmount
            : contractTokenBalance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapPairToken;

        _approve(address(this), address(swapFeesRouter), amountToSwap);
        swapFeesRouter.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            treasuryFeeRecipient,
            block.timestamp
        );
    }

    function isLiquidityManagementPhase() external view returns (bool) {
        return _isLiquidityManagementPhase;
    }

    function setLiquidityManagementPhase(
        bool isLiquidityManagementPhase_
    ) external onlyLiquidityManager {
        _isLiquidityManagementPhase = isLiquidityManagementPhase_;
    }

    function withdrawStuckEth(uint256 amount) public onlyOwner {
        (bool success, ) = address(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function withdrawStuckEth() public onlyOwner {
        withdrawStuckEth(address(this).balance);
    }

    function withdrawStuckTokens(
        IERC20 token,
        uint256 amount
    ) public onlyOwner {
        bool success = token.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    function withdrawStuckTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        withdrawStuckTokens(token, balance);
    }

    function airdropHolders(
        address[] memory wallets,
        uint256[] memory amounts
    ) external onlyOwner {
        if (wallets.length != amounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i];
            _transfer(msg.sender, wallet, amount);
        }
    }

    function isExcludedFromMaxWallet(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxWallet[account] || _isLpPair[account];
    }

    function excludeFromMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }

    function includeInMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = false;
    }

    function setMaxWalletEnabled(bool enabled) external onlyOwner {
        maxWalletEnabled = enabled;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        maxWalletAmount = amount;
    }

    function addLpPair(address _pair) external onlyOwner {
        _isLpPair[_pair] = true;
        emit LpPairAdded(_pair);
    }

    function removeLpPair(address _pair) external onlyOwner {
        _isLpPair[_pair] = false;
        emit LpPairRemoved(_pair);
    }

    function excludeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = true;
        emit AddressExcludedFromFees(_account);
    }

    function includeInFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = false;
        emit AddressIncludedInFees(_account);
    }

    function setFarmsFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }
        farmsFeeRecipient = _account;
        isExcludedFromFee[_account] = true;

    }

    function setStakingFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }
        stakingFeeRecipient = _account;
        isExcludedFromFee[_account] = true;

    }

    function setTreasuryFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }

        treasuryFeeRecipient = _account;
         isExcludedFromFee[_account] = true;
       
    }

    function setBuyFees(
        uint256 _burnBuyFee,
        uint256 _farmsBuyFee,
        uint256 _stakingBuyFee,
        uint256 _treasuryBuyFee
    ) public onlyOwner {
        if (
            _burnBuyFee + _farmsBuyFee + _stakingBuyFee + _treasuryBuyFee >
            MAX_FEE
        ) {
            revert FeeTooHigh();
        }

        burnBuyFee = _burnBuyFee;
        farmsBuyFee = _farmsBuyFee;
        stakingBuyFee = _stakingBuyFee;
        treasuryBuyFee = _treasuryBuyFee;
        totalBuyFee = burnBuyFee + farmsBuyFee + stakingBuyFee + treasuryBuyFee;
    }

    function setSellFees(
        uint256 _burnSellFee,
        uint256 _farmsSellFee,
        uint256 _stakingSellFee,
        uint256 _treasurySellFee
    ) public onlyOwner {
        if (
            _burnSellFee + _farmsSellFee + _stakingSellFee + _treasurySellFee >
            MAX_FEE
        ) {
            revert FeeTooHigh();
        }

        burnSellFee = _burnSellFee;
        farmsSellFee = _farmsSellFee;
        stakingSellFee = _stakingSellFee;
        treasurySellFee = _treasurySellFee;
        totalSellFee =
            burnSellFee +
            farmsSellFee +
            stakingSellFee +
            treasurySellFee;
    }

    function setLiquidityManager(
        address _liquidityManager,
        bool _isManager
    ) public onlyOwner {
        isLiquidityManager[_liquidityManager] = _isManager;
    }

    function addWhitelistedFactory(address _factory) public onlyOwner {
        isWhitelistedFactory[_factory] = true;
    }

    function removeWhitelistedFactory(address _factory) public onlyOwner {
        isWhitelistedFactory[_factory] = false;
        _currentCacheVersion++;
    }

    function setIndirectSwapFeeEnabled(
        bool _indirectSwapFeeEnabled
    ) public onlyOwner {
        indirectSwapFeeEnabled = _indirectSwapFeeEnabled;
    }

    function setPairAutoDetectionEnabled(
        bool _pairAutoDetectionEnabled
    ) public onlyOwner {
        pairAutoDetectionEnabled = _pairAutoDetectionEnabled;
    }

    function setSniperBuyFeeEnabled(
        bool _sniperBuyFeeEnabled
    ) public onlyOwner {
        sniperBuyFeeEnabled = _sniperBuyFeeEnabled;
    }

    function setSniperSellFeeEnabled(
        bool _sniperSellFeeEnabled
    ) public onlyOwner {
        sniperSellFeeEnabled = _sniperSellFeeEnabled;
    }

    function setSwapFeesAtAmount(uint256 _swapFeesAtAmount) public onlyOwner {
        swapFeesAtAmount = _swapFeesAtAmount;
    }

    function setMaxSwapFeesAmount(uint256 _maxSwapFeesAmount) public onlyOwner {
        maxSwapFeesAmount = _maxSwapFeesAmount;
    }

    function setSwappingFeesEnabled(
        bool _swappingFeesEnabled
    ) public onlyOwner {
        swappingFeesEnabled = _swappingFeesEnabled;
    }

    function setFeeDiscountOracle(IFeeDiscountOracle _oracle) public onlyOwner {
        feeDiscountOracle = _oracle;
    }

    function addBot(address account) public onlyOwner {
        isBot[account] = true;
    }

    function removeBot(address account) public onlyOwner {
        isBot[account] = false;
    }

    function setSwapFeesRouter(address _swapFeesRouter) public onlyOwner {
        swapFeesRouter = ISwapV2Router01(_swapFeesRouter);
    }    

    function setTradingEnabledTimestamp(uint256 _timestamp) public onlyOwner {
        if (tradingEnabled && tradingEnabledTimestamp <= block.timestamp) {
            revert TradingAlreadyEnabled();
        }

        if (tradingEnabled && _timestamp < block.timestamp) {
            revert TimestampIsInThePast();
        }

        tradingEnabledTimestamp = _timestamp;
    }    

    function enableTrading() public onlyOwner {
        if (tradingEnabled) revert TradingAlreadyEnabled();
        tradingEnabled = true;

        if (tradingEnabledTimestamp < block.timestamp) {
            tradingEnabledTimestamp = block.timestamp;
        }

        swappingFeesEnabled = true;
    }
}




/*     function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
    }
    receive() external payable {}
} */