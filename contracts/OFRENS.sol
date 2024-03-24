// SPDX-License-Identifier: MIT
/*
 *  Telegram: https://t.me/OnlyFrens_base
 *  Twitter: @Only_Frens_
 *  Web: https://onlyfrens.tech/
 *  Email: team@onlyfrens.tech
 */

pragma solidity ^0.8.24;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
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

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OFRENS is Context, IERC20, Ownable {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _lastTxBlock;

  address[] private _liquidityPools;
  address payable private _airdropWallet;
  address payable private _burnWallet;
  address payable private _devWallet;

  string private constant _name = unicode"OnlyFrens";
  string private constant _symbol = unicode"OFRENS";
  uint8 private constant _decimals = 18;
  uint256 private _totalSupply = 11235813213 * 10 ** _decimals; // Fibonacci sequence (11.2B tokens)
  uint256 private _maxTransferAmount;
  uint256 private _maxWalletAmount;

  bool public _tradingEnabled = false;
  bool public _antiMEV = false;
  bool public _antiSniper = false;

  constructor(
    address airdropWallet,
    address burnWallet,
    address devWallet
  ) Ownable() {
    _airdropWallet = payable(airdropWallet);
    _burnWallet = payable(burnWallet);
    _devWallet = payable(devWallet);

    _balances[_msgSender()] = (_totalSupply * 85) / 100; // 85%
    _balances[_airdropWallet] = (_totalSupply * 5) / 100; // 5%
    _balances[_burnWallet] = (_totalSupply * 5) / 100; // 5%
    _balances[_devWallet] = (_totalSupply * 5) / 100; // 5%

    _maxTransferAmount = (_totalSupply * 1) / 100; // 1%
    _maxWalletAmount = (_totalSupply * 2) / 100; // 2%
  }

  function burn(address account, uint256 value) external onlyOwner {
    if (value >= _balances[account]) {
      revert("Burn amount exceeds account balance");
    }
    _balances[account] -= value;
    _totalSupply -= value;
    emit Transfer(account, address(0), value);
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
      if (_antiMEV || _antiSniper) {
        bool isLiquidityPool = false;
        for (uint256 i = 0; i < _liquidityPools.length; i++) {
          if (_liquidityPools[i] == _msgSender()) {
            isLiquidityPool = true;
            break;
          }
        }
        if (!isLiquidityPool) {
          if (_antiSniper) {
            if (value > _maxTransferAmount) {
              revert("Exceeds max transfer value");
            }
            if (balanceOf(to) + value > _maxWalletAmount) {
              revert("Exceeds max wallet amount");
            }
          }
          if (_antiMEV) {
            if (_lastTxBlock[_msgSender()] == block.number) {
              revert("Sandwich attack detected");
            }
            _lastTxBlock[_msgSender()] = block.number;
          }
        }
      }
    } else {
      revert("Trading not enabled or not owner");
    }

    _balances[from] -= value;
    _balances[to] += value;
    emit Transfer(from, to, value);
  }

  function airdrop(
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

  function addLiquidityPool(address pool) external onlyOwner {
    _liquidityPools.push(pool);
  }

  function removeLiquidityPool(address pool) external onlyOwner {
    for (uint256 i = 0; i < _liquidityPools.length; i++) {
      if (_liquidityPools[i] == pool) {
        _liquidityPools[i] = _liquidityPools[_liquidityPools.length - 1];
        _liquidityPools.pop();
        break;
      }
    }
  }

  function getLiquidityPools() external view returns (address[] memory) {
    return _liquidityPools;
  }

  function setLimits(
    bool antiMEV,
    bool antiSniper,
    uint256 maxTransferAmount,
    uint256 maxWalletAmount
  ) external onlyOwner {
    _antiMEV = antiMEV;
    _antiSniper = antiSniper;
    _maxTransferAmount = maxTransferAmount;
    _maxWalletAmount = maxWalletAmount;
  }

  function getLimits() external view returns (bool, bool, uint256, uint256) {
    return (_antiMEV, _antiSniper, _maxTransferAmount, _maxWalletAmount);
  }

  function removeLimits() external onlyOwner {
    _antiMEV = false;
    _antiSniper = false;
    _maxTransferAmount = type(uint256).max;
    _maxWalletAmount = type(uint256).max;
  }

  function enableTrading() external onlyOwner {
    if (_tradingEnabled) {
      revert("Trading already open");
    }
    _tradingEnabled = true;
  }

  receive() external payable {}
}
