// SPDX-License-Identifier: MIT
/* MechAnime pushes the evolution of meme tokens further into art and lore. 
 * Inspired by master game artist Akihiko Yoshida, creator of Final Fantasy.
 * Contract is a gas optimized ERC20 with anti-snipe and anti-MEV features.
 * Designed so V2 Liquidity Pool can be created and locked before trading.
 * Implements ReentrancyGuard for additional security.
 *
 * Web: https://mechanime.site/
 * TG: t.me/mech_anime 
 * X: @mechanime_ */

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

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant NOT_ENTERED = 1;
  uint256 private constant ENTERED = 2;

  uint256 private _status;

  error ReentrancyGuardReentrantCall();

  constructor() {
    _status = NOT_ENTERED;
  }

  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be NOT_ENTERED
    if (_status == ENTERED) {
      revert ReentrancyGuardReentrantCall();
    }

    // Any calls to nonReentrant after this point will fail
    _status = ENTERED;
  }

  function _nonReentrantAfter() private {
    _status = NOT_ENTERED;
  }

  function _reentrancyGuardEntered() internal view returns (bool) {
    return _status == ENTERED;
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
}

contract MechAnimeV1 is Context, IERC20, Ownable, ReentrancyGuard {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _lastTxBlock;

  address public immutable _deployer;
  address public _pair;

  string private constant _name = unicode"MechAnime";
  string private constant _symbol = unicode"MECHA";
  uint8 private constant _decimals = 18;
  uint256 private _totalSupply = 42000000000 * 10 ** _decimals; // 42 billion
  uint256 public _maxWallet;

  bool private _tradingEnabled = false;
  bool public _noSnipe = true;
  bool public _noMEV = true;

  IUniswapV2Router02 private _router;

  constructor(address _burn, address _team) Ownable() {
    _deployer = _msgSender();
    _balances[_deployer] = (_totalSupply * 90) / 100; // 90% LP
    _balances[_burn] = (_totalSupply * 5) / 100; // 5%
    _balances[_team] = (_totalSupply * 5) / 100; // 5%
    _maxWallet = (_totalSupply * 3) / 100; // 3%
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

  function _approve(
    address owner,
    address spender,
    uint256 value
  ) private nonReentrant {
    if (owner == address(0) || spender == address(0)) {
      revert("ERC20: approve from/to the zero address");
    }
    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(
    address from,
    address to,
    uint256 value
  ) private nonReentrant {
    if (value <= 0) {
      revert("ERC20: value must be greater than zero");
    }
    if (_tradingEnabled || _msgSender() == _deployer) {
      if (to != address(_router) && to != address(_pair)) {
        if (_noSnipe) {
          if (balanceOf(to) + value > _maxWallet) {
            revert("Exceeds max wallet");
          }
        }
        if (_noMEV) {
          if (_lastTxBlock[_msgSender()] == block.number) {
            revert("Sandwich attack");
          }
          _lastTxBlock[_msgSender()] = block.number;
        }
      }
    } else {
      revert("Trading not enabled");
    }

    _balances[from] -= value;
    _balances[to] += value;
    emit Transfer(from, to, value);
  }

  function burn(uint256 value) public virtual returns (bool) {
    if (value > _balances[_msgSender()]) {
      revert("Burn amount exceeds balance");
    }
    _balances[_msgSender()] -= value;
    _totalSupply -= value;
    emit Transfer(_msgSender(), address(0), value);
    return true;
  }

  function setLimits(
    bool noMEV,
    bool noSnipe,
    uint256 maxWalletAmount
  ) public virtual returns (bool) {
    _checkOwner();
    _noMEV = noMEV;
    _noSnipe = noSnipe;
    _maxWallet = maxWalletAmount;
    return true;
  }

  function createLP(address router) public virtual returns (bool) {
    _checkOwner();
    _router = IUniswapV2Router02(router);
    _approve(address(this), address(_router), _totalSupply);
    _pair = IUniswapV2Factory(_router.factory()).createPair(
      address(this),
      _router.WETH()
    );
    IERC20(_pair).approve(address(_router), type(uint).max);
    return true;
  }

  function enableTrading() public virtual returns (bool) {
    _checkOwner();
    _tradingEnabled = true;
    return true;
  }

  receive() external payable {}
}