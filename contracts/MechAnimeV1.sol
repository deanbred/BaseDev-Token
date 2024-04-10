// SPDX-License-Identifier: MIT
/* MechAnime pushes the evolution of base meme tokens further into art and lore. 
Inspired by master game artist Akihiko Yoshida, creator of Final Fantasy.
Web: https://mechanime.site/
Telegram: t.me/mech_anime 
Twitter: @mechanime_ */

pragma solidity ^0.8.24;

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

  error OwnableUnauthorizedAccount(address account);
  error OwnableInvalidOwner(address owner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    if (owner() != _msgSender()) {
      revert OwnableUnauthorizedAccount(_msgSender());
    }
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    if (newOwner == address(0)) {
      revert OwnableInvalidOwner(address(0));
    }
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 value
  ) external returns (bool);
}

interface IUniswapV2Factory {
  function createPair(
    address tokenA,
    address tokenB
  ) external returns (address pair);
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract MechAnimeV1 is Context, IERC20, Ownable {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _lastTxBlock;

  address public immutable deployer =
    0xEA683198b85e02E4A85dc334332c90D26391D0E3;
  address public immutable airdrop = 0x7Ac2d9FF78930db172b51a72E3B954CB9d6Ed269;
  address public immutable team = 0xdf921074AF44aABA0da0A7B2F0F5fa0D9FddE71f;

  bool public _antiMEV = true;
  bool public _antiSniper = true;

  string private constant _name = unicode"MechAnime";
  string private constant _symbol = unicode"MECHA";
  uint8 private constant _decimals = 18;
  uint256 private _totalSupply = 42000000000 * 10 ** _decimals; // 42 billion
  uint256 public _maxWallet = (_totalSupply * 3) / 100; // 3%

  IUniswapV2Router02 private uniswapV2Router;
  address public uniswapV2Pair;
  bool public _tradingEnabled = false;

  constructor() Ownable() {
    _balances[_msgSender()] = (_totalSupply * 90) / 100; // 90%
    _balances[airdrop] = (_totalSupply * 6) / 100; // 6%
    _balances[team] = (_totalSupply * 4) / 100; // 4%
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(_msgSender(), to, value);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 value
  ) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, value);
    return true;
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 value
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      if (currentAllowance < value) {
        revert("ERC20InsufficientAllowance");
      }
      unchecked {
        _approve(owner, spender, currentAllowance - value);
      }
    }
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, value);
    _transfer(from, to, value);
    return true;
  }

  function _approve(address owner, address spender, uint256 value) private {
    if (owner == address(0) || spender == address(0)) {
      revert("ERC20: approve from/to the zero address");
    }
    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(address from, address to, uint256 value) private {
    if (from == address(0) || to == address(0)) {
      revert("ERC20: transfer from/to the zero address");
    }
    if (value <= 0) {
      revert("ERC20: transfer value must be greater than zero");
    }
    if (_tradingEnabled || _msgSender() == owner()) {
      if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
        if (_antiSniper) {
          if (balanceOf(to) + value > _maxWallet) {
            revert("Exceeds max wallet");
          }
        }
        if (_antiMEV) {
          if (_lastTxBlock[_msgSender()] == block.number) {
            revert("Sandwich attack");
          }
          _lastTxBlock[_msgSender()] = block.number;
        }
      }
    } else {
      revert("Trading not enabled or not owner");
    }

    _balances[from] -= value;
    _balances[to] += value;
    emit Transfer(from, to, value);
  }

  function airdropHolders(
    address[] memory accounts,
    uint256[] memory amounts
  ) external onlyOwner {
    if (accounts.length != amounts.length) {
      revert("arrays must be the same length");
    }
    for (uint256 i = 0; i < accounts.length; i++) {
      address account = accounts[i];
      uint256 amount = amounts[i];
      _transfer(msg.sender, account, amount);
    }
  }

  function setLimits(
    bool antiMEV,
    bool antiSniper,
    uint256 maxWalletAmount
  ) external onlyOwner {
    _antiMEV = antiMEV;
    _antiSniper = antiSniper;
    _maxWallet = maxWalletAmount;
  }

  function getLimits() external view returns (bool, bool, uint256) {
    return (_antiMEV, _antiSniper, _maxWallet);
  }

  function enableTrading() external onlyOwner {
    if (_tradingEnabled) {
      revert("Trading already open");
    }

    uniswapV2Router = IUniswapV2Router02(
      0x4cf76043B3f97ba06917cBd90F9e3A2AAC1B306e
    ); // base address
    _approve(address(this), address(uniswapV2Router), _totalSupply);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
      address(this),
      uniswapV2Router.WETH()
    );
    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    _tradingEnabled = true;
  }

  receive() external payable {}
}
