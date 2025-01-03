// SPDX-License-Identifier: MIT
/* MechAnime pushes the evolution of meme tokens further into art and lore.
 * Inspired by master game artist Akihiko Yoshida, creator of Final Fantasy.
 * Contract is a gas optimized ERC20 with Sniper and MEV protection.
 * Designed so liquidity pool is created and locked before trading.
 *
 * Web: https://mechanime.site/
 * TG: t.me/mech_anime
 * X: @mechanime_
 */

pragma solidity ^0.8.20;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event OwnershipTransferred(address indexed user, address indexed newOwner);

  /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

  address public owner;

  modifier onlyOwner() virtual {
    require(msg.sender == owner, "UNAUTHORIZED");

    _;
  }

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _owner) {
    owner = _owner;

    emit OwnershipTransferred(address(0), _owner);
  }

  /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

  function transferOwnership(address newOwner) public virtual onlyOwner {
    owner = newOwner;

    emit OwnershipTransferred(msg.sender, newOwner);
  }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  uint8 public immutable decimals;

  /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256 internal immutable INITIAL_CHAIN_ID;

  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

  mapping(address => uint256) public nonces;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

  function approve(
    address spender,
    uint256 amount
  ) public virtual returns (bool) {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount) public virtual returns (bool) {
    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool) {
    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual {
    require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      address recoveredAddress = ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            keccak256(
              abi.encode(
                keccak256(
                  "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
              )
            )
          )
        ),
        v,
        r,
        s
      );

      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "INVALID_SIGNER"
      );

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(name)),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 amount) internal virtual {
    totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    balanceOf[from] -= amount;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
      totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }
}

contract MechAnimeV0 is ERC20, Owned {
  bool public tradingEnabled = false;
  uint256 public maxTransferAmount;
  uint256 public maxWalletAmount;
  uint256 private restrictionEndTimestamp;
  address public baseLP;

  constructor() ERC20("MechAnime", "MECHA", 18) Owned(msg.sender) {
    uint256 tokenSupply = 42_000_000_000e18;
    _mint(msg.sender, tokenSupply);
    maxTransferAmount = (tokenSupply * 2) / 100; // 2%
    maxWalletAmount = (tokenSupply * 3) / 100; // 3%
  }

  function setBasePool(address pool) external onlyOwner {
    baseLP = pool;
  }

  function enableTrading() external onlyOwner {
    require(baseLP != address(0));
    tradingEnabled = true;
  }

  function renounceOwnership() external onlyOwner {
    require(tradingEnabled);
    restrictionEndTimestamp = block.timestamp + 4 hours;
    transferOwnership(address(0));
  }

  function removeRestrictions() external {
    require(block.timestamp >= restrictionEndTimestamp);
    maxTransferAmount = type(uint256).max;
    maxWalletAmount = type(uint256).max;
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    require(tradingEnabled || tx.origin == owner);
    require(amount < maxTransferAmount || tx.origin == owner);

    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      require(
        balanceOf[to] + amount < maxWalletAmount ||
          to == baseLP ||
          tx.origin == owner
      );
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    require(tradingEnabled || tx.origin == owner);
    require(amount < maxTransferAmount || tx.origin == owner);

    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      require(
        balanceOf[to] + amount < maxWalletAmount ||
          to == baseLP ||
          tx.origin == owner
      );
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }
}
