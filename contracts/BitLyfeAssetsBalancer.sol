pragma solidity 0.6.11; // 5ef660b1

// SPDX-License-Identifier: UNLICENSED

import "./BitLyfe.sol";

contract BAEXAssetsBalancer is abstractBitLyfeAssetsBalancer, LinkedToStableCoins {
    address public bit_lyfe;
    address public pancakeRouter;

    string public name;
    uint256 public usdt_percent;

    // Max slippage of swap is 2 %, fixed point decimal 3  ( 1% == 10 )
    uint public max_slippage = 20;

    constructor() public {
        name = "Assets Balancer Contract";
        owner = msg.sender;

        pancakeRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        usdtContract = 0xde3A24028580884448a5397872046a019649b084;
        daiContract = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;

        // Store 20% of collateral in USDT
        usdt_percent = fmk * 20 / 100;
    }

    function autoBalancing() public override returns (bool){
        if ( usdtContract == daiContract ) return false;
        uint256 usdtBal = balanceOfOtherERC20AtAddress(usdtContract, bit_lyfe);
        uint256 daiBal = balanceOfOtherERC20AtAddress(daiContract, bit_lyfe);
        uint256 needToSellUSDT = 0;
        uint256 needToSellDAI = 0;
        uint256 in_amount;
        uint256 out_amount;
        if ( usdtBal > ( (daiBal+usdtBal) * usdt_percent / fmk) ) {
            needToSellUSDT = usdtBal - ((daiBal+usdtBal) * usdt_percent / fmk);
        } else if ( usdtBal * 2 < ((daiBal+usdtBal) * usdt_percent / fmk) ) {
            needToSellDAI = ((daiBal+usdtBal) * usdt_percent / fmk) - usdtBal;
        }
        if ( needToSellUSDT == 0 && needToSellDAI == 0 ) return false;
        // Using path ERC20 -> WETH -> DAI because most of liquidity in pairs with ETH
        // and resulted amount of tokens will be greater than in direct pair
        address[] memory path = new address[](3);
        if ( needToSellUSDT > 0 ) {
            path[0] = usdtContract;
            path[1] = IPancakeRouter02(pancakeRouter).WETH();
            path[2] = daiContract;
            in_amount = fixedPointAmountToTokenAmount(usdtContract,needToSellUSDT);
            out_amount = fixedPointAmountToTokenAmount(daiContract,needToSellUSDT) * (1000-max_slippage) / 1000;
            IERC20(usdtContract).safeTransferFrom(bit_lyfe,address(this),in_amount);
            IERC20(usdtContract).safeIncreaseAllowance(pancakeRouter,in_amount);

            IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(in_amount, out_amount, path, bit_lyfe, block.timestamp);
        } else if ( needToSellDAI > 0 ) {
            path[0] = daiContract;
            path[1] = IPancakeRouter02(pancakeRouter).WETH();
            path[2] = usdtContract;
            in_amount = fixedPointAmountToTokenAmount(daiContract,needToSellDAI);
            out_amount = fixedPointAmountToTokenAmount(usdtContract,needToSellDAI) * (1000-max_slippage) / 1000;
            IERC20(daiContract).safeTransferFrom(bit_lyfe,address(this),in_amount);
            IERC20(daiContract).safeIncreaseAllowance(pancakeRouter,in_amount);

            IPancakeRouter02(pancakeRouter).swapExactTokensForTokens(in_amount, out_amount, path, bit_lyfe, block.timestamp);
        }
        return true;
    }

    function setTokenAddress(address _token_address) public onlyOwner {
        bit_lyfe = payable(_token_address);
    }

    function setUSDTPercent(uint256 _usdt_percent) public onlyOwner {
        usdt_percent = _usdt_percent;
    }

    function setMaxSlippage(uint256 _max_slippage) public onlyOwner {
        max_slippage = _max_slippage;
    }

    function setPangolinRouter(address _pancakeRouter) public onlyOwner {
        pancakeRouter = payable(_pancakeRouter);
    }
}