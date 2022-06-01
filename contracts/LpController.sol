// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function updatePool() external payable;
}

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
}

interface IPair {
    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract LpController is Ownable {
    IPool public pool;
    IRouter public router;
    address public lpAdmin;
    address public WETH;

    address[] public pairs;

    mapping(address => address) pairToToken;

    constructor(
        IPool _pool,
        address _lpAdmin,
        address _WETH,
        address _router
    ) {
        pool = _pool;
        lpAdmin = _lpAdmin;
        WETH = _WETH;
        router = IRouter(_router);
    }

    function setRouter(address _router) external onlyOwner {
        router = IRouter(_router);
    }

    function setLpAdmin(address _lpAdmin) external onlyOwner {
        lpAdmin = _lpAdmin;
    }

    function setPool(IPool _pool) external onlyOwner {
        pool = _pool;
    }

    function setWETH(address _WETH) external onlyOwner {
        WETH = _WETH;
    }

    function getPairsLength() external view returns (uint256) {
        return pairs.length;
    }

    function addPair(address _pair) external onlyOwner {
        require(pairToToken[_pair] == address(0), "Already Set");
        pairs.push(_pair);
        IPair pair = IPair(_pair);
        if (pair.token0() == WETH) {
            pairToToken[_pair] = pair.token1();
        } else {
            pairToToken[_pair] = pair.token0();
        }
    }

    function collectLpAndUpdatePool() external {
        for (uint256 i = 0; i < pairs.length; i++) {
            IPair pair = IPair(pairs[i]);
            uint256 lpAdminBalance = pair.balanceOf(lpAdmin);
            if (lpAdminBalance > 0) {
                pair.transferFrom(lpAdmin, address(this), lpAdminBalance);
                address token = pairToToken[pairs[i]];
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = WETH;
                router.removeLiquidityETHSupportingFeeOnTransferTokens(
                    token,
                    lpAdminBalance,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    IERC20(token).balanceOf(address(this)),
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            }
        }
        pool.updatePool{value: address(this).balance}();
    }
}
