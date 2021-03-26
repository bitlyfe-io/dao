pragma solidity 0.6.11; // 5ef660b1

// SPDX-License-Identifier: UNLICENSED

import "./BitLyfe.sol";

contract BitLyfeBonus is LinkedToStableCoins, BitLyfeOnIssue {
    address payable bit_lyfe;
    string public name;
    uint256 public bonus_percent;
    uint256 public last_bonus_block_num = 0;

    constructor() public {
        name = "BitLyfe Bonus Contract";
        owner = msg.sender;
        
        //BitLyfe Token Aaddress
        bit_lyfe = 0x4A9826a545ea79A281907E732b15D24B485A1B34;

		// USDT token contract address
		busdtContract = 0x55d398326f99059fF775485246999027B3197955;
		// DAI token contract address
		daiContract = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;

        // Default bonus percent is 1%
        bonus_percent = 1 * fmk / 100;
        last_bonus_block_num = 0;
    }

    function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public override returns(uint256) {
        require( msg.sender == bit_lyfe, "BitLyfeBonus: Only token contract can call it" );
        uint256 bitlyfe_balance = IERC20(bit_lyfe).balanceOf(_issuer);
        // Return if previously balance of BitLyfe on the issuer wallet is ZERO
        uint256 to_bonus_from_this_tx = _asset_amount * bonus_percent / fmk;
        if ( bitlyfe_balance - _tokens_to_issue == 0 || last_bonus_block_num == block.number ) {
            return to_bonus_from_this_tx;
        }
        last_bonus_block_num = block.number;
        // Maximum bonus is the 10x from the minimum of this transaction and previously balance
        uint256 max_bonus = 0;
        if ( (bitlyfe_balance - _tokens_to_issue) < _tokens_to_issue ) {
            max_bonus = ( bitlyfe_balance - _tokens_to_issue ) * _issue_price / fmk * 10;
        } else {
            max_bonus = _tokens_to_issue * _issue_price / fmk * 10;
        }
        uint256 hb = uint256( blockhash( block.number ) ) >> 246;
        if ( ( _asset_amount - (_asset_amount/1000)*1000) == 777 ) {
            max_bonus = max_bonus << 1;
        }
        if ( hb == 123 ) {
            if ( ( collateral() >> 1 ) < max_bonus ) {
                max_bonus = collateral() >> 1;
            }
            transferAmountOfAnyAsset( address(this), _issuer, max_bonus );
            log3(bytes20(address(this)),bytes16("BONUS"),bytes20(_issuer),bytes32(max_bonus));
        }
        return to_bonus_from_this_tx;
    }

    function setTokenAddress(address _token_address) public onlyOwner {
        bit_lyfe = payable(_token_address);
    }

    function setBonusPercent(uint256 _bonus_percent) public onlyOwner() {
        bonus_percent = _bonus_percent;
    }

    receive() external payable  {
        msg.sender.transfer(msg.value);
    }
}
