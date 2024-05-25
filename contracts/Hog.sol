// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseTemplate is ERC20, Ownable {
    uint256 public max_transfer;
    address public liquidityPool;
    uint256 public limitLiftTimestamp = type(uint256).max;

    constructor() ERC20("MyFrigga", "FRIGGA") Ownable(msg.sender) {
        _mint(owner(), 42_000_000_000e18);
        max_transfer = totalSupply() / 30;
    }

    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        liquidityPool = _liquidityPool;
        limitLiftTimestamp = block.timestamp + 4 hours;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // We apply some restrictions for the first period of trading to reduce sniping.
        if (block.timestamp < limitLiftTimestamp) {
            if (liquidityPool == address(0)) {
                require(from == owner() || to == owner(), "Trading not started yet");
            }
            // Allow deployer (owner) to send/receive any amount and the liquidityPool to receive any amount.
            // This allows for loading of the LP, and for people to sell tokens into the LP while limit is active.
            if (from != owner() && to != owner() && to != liquidityPool) {
                // Enforce limit on receiving wallet.
                require(balanceOf(to) + amount <= max_transfer, "Max per wallet exceeded!");
            }
        }

        super._update(from, to, amount);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 recipientsCount = recipients.length;
        require(recipientsCount == amounts.length, "Recipients and amounts arrays must have the same length");
        for (uint256 i; i < recipientsCount; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }
}