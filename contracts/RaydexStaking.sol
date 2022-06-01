// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ILpController {
    function collectLpAndUpdatePool() external;
}

contract RaydexStaking is Ownable, ReentrancyGuard {
    using Address for address;

    address public treasury;

    IERC20 public RDX;

    uint8 public fee;

    uint256 public totalReward;

    struct PoolInfo {
        uint256 deposit;
        uint256 accTokenPerShare;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 reward;
    }

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfo;

    ILpController lpController;

    bool public collectStatus;

    constructor(address _treasury, address rdx) {
        treasury = _treasury;
        RDX = IERC20(rdx);
    }

    function setLpController(address controller) external onlyOwner {
        lpController = ILpController(controller);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setCollectStatus(bool status) external onlyOwner {
        collectStatus = status;
    }

    function callCollect() internal {
        if (collectStatus) {
            lpController.collectLpAndUpdatePool();
        }
    }

    function deposit(uint256 amount) external nonReentrant {
        callCollect();
        UserInfo storage user = userInfo[msg.sender];

        uint256 pending = (poolInfo.accTokenPerShare * user.amount) /
            1e12 -
            user.rewardDebt;
        if (pending > 0) {
            Address.sendValue(payable(msg.sender), pending);
            user.reward += pending;
            totalReward += pending;
        }

        if (amount > 0) {
            RDX.transferFrom(msg.sender, address(this), amount);
            user.amount += amount;
            poolInfo.deposit += amount;
        }

        user.rewardDebt = (user.amount * poolInfo.accTokenPerShare) / 1e12;
    }

    function withdraw(uint256 amount) external nonReentrant {
        callCollect();
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = (poolInfo.accTokenPerShare * user.amount) /
            1e12 -
            user.rewardDebt;
        if (pending > 0) {
            Address.sendValue(payable(msg.sender), pending);
            user.reward += pending;
            totalReward += pending;
        }

        user.amount -= amount;
        poolInfo.deposit -= amount;
        user.rewardDebt = (poolInfo.accTokenPerShare * user.amount) / 1e12;
    }

    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "No staking amount");
        RDX.transfer(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function updatePool() public payable {
        if (msg.value == 0) {
            return;
        }

        if (poolInfo.deposit == 0) {
            return;
        }
        poolInfo.accTokenPerShare += (msg.value * 1e12) / poolInfo.deposit;
    }

    function pendingReward(address account) external view returns (uint256) {
        UserInfo storage user = userInfo[account];
        if (poolInfo.deposit == 0) {
            return 0;
        }
        return
            (user.amount * poolInfo.accTokenPerShare) / 1e12 - user.rewardDebt;
    }

    receive() external payable {}

    function rescueToken(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }
}
