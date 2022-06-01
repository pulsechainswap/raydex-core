// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RaydexBurn is Ownable {
    IERC20 public rdx;
    uint8 public reward = 1; // 1%
    uint8 public adminReward = 0; // 0%
    uint256 public minBurnAmount = 0;
    uint256 public minHoldRequired = 0;
    uint256 public totalBurn;
    IERC20 public requiredToken;
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address public admin;

    constructor(IERC20 _rdx) {
        rdx = _rdx;
        admin = msg.sender;
        requiredToken = _rdx;
    }

    modifier onlyHolders() {
        if (minHoldRequired > 0) {
            require(
                requiredToken.balanceOf(_msgSender()) > minHoldRequired,
                "mininum Hold Required"
            );
        }
        _;
    }

    function setMinHold(IERC20 rToken, uint256 minHold) external onlyOwner {
        requiredToken = rToken;
        minHoldRequired = minHold;
    }

    function setRewards(uint8 _reward, uint8 _adminReward) external onlyOwner {
        reward = _reward;
        adminReward = _adminReward;
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    function setMinBurnAmount(uint256 amount) external onlyOwner {
        minBurnAmount = amount;
    }

    function burn() external onlyHolders {
        uint256 amount = rdx.balanceOf(address(this));
        require(amount >= minBurnAmount, "Less than minBurn Amount");
        uint256 userAmount = (amount * reward) / 100;
        uint256 adminAmount = (amount * adminReward) / 100;
        uint256 burnAmount = amount - userAmount - adminAmount;
        if (userAmount > 0) {
            rdx.transfer(msg.sender, userAmount);
        }
        if (adminAmount > 0) {
            rdx.transfer(admin, adminAmount);
        }
        rdx.transfer(burnAddress, burnAmount);
        totalBurn += burnAmount;
    }
}
