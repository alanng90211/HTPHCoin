// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HideThePainHarold is ERC20, Ownable {
    uint256 private constant TAX_RATE = 3; // Represents 0.3%
    uint256 private constant WALLET_TAX_SHARE = 250; // Represents 0.25%
    uint256 private constant POOL_TAX_SHARE = 50;  // Represents 0.05%

    address public taxWallet;
    address public liquidityPool;
    mapping(address => bool) public whitelist;
    bool public whitelistEnabled = false;

    constructor(address _owner, address _taxWallet, address _liquidityPool)
        ERC20("Hide The Pain Harold", "HAROLD")
        Ownable(_owner) 
    {
        taxWallet = _taxWallet;
        liquidityPool = _liquidityPool;
        _mint(_owner, 1000000 * 10 ** decimals());  // Mint initial supply
    }

    function taxedTransfer(address sender, address recipient, uint256 amount) public {
        require(balanceOf(sender) >= amount, "Insufficient balance");
        if (whitelistEnabled && (!whitelist[sender] || !whitelist[recipient])) {
            revert("Whitelist is enabled and one of the addresses is not whitelisted");
        }
        
        uint256 taxAmount = (amount * TAX_RATE) / 1000;
        uint256 walletTax = (taxAmount * WALLET_TAX_SHARE) / (WALLET_TAX_SHARE + POOL_TAX_SHARE);
        uint256 poolTax = taxAmount - walletTax;
        uint256 amountAfterTax = amount - taxAmount;

        _transfer(sender, taxWallet, walletTax);
        _transfer(sender, liquidityPool, poolTax);
        _transfer(sender, recipient, amountAfterTax);
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function toggleWhitelist() public onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    // Fallback function to revert all transactions that do not call an existing function
    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }
}
