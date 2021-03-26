pragma solidity 0.6.11; // 5ef660b1

// SPDX-License-Identifier: UNLICENSED

import "./BitLyfe.sol";

contract BitLyfeReferral is LinkedToStableCoins, BitLyfeOnIssue {
    address payable bit_lyfe;

    string public name;
    uint256 public referral_percent1;
    uint256 public referral_percent2;
    uint256 public referral_percent3;


    mapping (address => address) partners;
    mapping (address => uint256) referral_balance;

    constructor() public {
        name = "BitLyfe Partners Program";
        owner = msg.sender;

        // Default referral percents is 
        //  2%      level 1
        //  1.5%    level 2
        //  0.5%    level 3
        referral_percent1 = 20 * fmk / 1000;
        referral_percent2 = 15 * fmk / 1000;
        referral_percent3 = 5 * fmk / 1000;

        //BitLyfe Token Aaddress
        bit_lyfe = 0x4A9826a545ea79A281907E732b15D24B485A1B34;
		// USDT token contract address
		busdtContract = 0x55d398326f99059fF775485246999027B3197955;
		// DAI token contract address
		daiContract = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    }

    function balanceOf(address _sender) public view returns (uint256 balance) {
        return referral_balance[_sender];
    }

    /**
    * @dev When someone issues BitLyfe tokens, 4% from the amount will be transferred from
	* @dev the BitLyfeReferral smart-contract to his referral partner.
    */
    function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public override returns(uint256) {
        require( msg.sender == bit_lyfe, "BitLYfeReferral: Only token contract can call it" );
        address partner1 = partners[_issuer];
        if ( partner1 == address(0) ) {
            if ( _partner == address(0) ) return 0;
            partners[_issuer] = _partner;
            partner1 = _partner;
        }
        uint256 assets_to_trans1 = (_tokens_to_issue*_issue_price/fmk) * referral_percent1 / fmk;
        uint256 assets_to_trans2 = (_tokens_to_issue*_issue_price/fmk) * referral_percent2 / fmk;
        uint256 assets_to_trans3 = (_tokens_to_issue*_issue_price/fmk) * referral_percent3 / fmk;
        if (assets_to_trans1 + assets_to_trans2 + assets_to_trans3 == 0) return 0;
        uint256 assets_to_trans = 0;

        if (assets_to_trans1 > 0) {
            referral_balance[partner1] = referral_balance[partner1] + assets_to_trans1;
            assets_to_trans = assets_to_trans + assets_to_trans1;
        }
        address partner2 = partners[partner1];
        if ( partner2 != address(0) ) {
            if (assets_to_trans2 > 0) {
                referral_balance[partner2] = referral_balance[partner2] + assets_to_trans2;
                assets_to_trans = assets_to_trans + assets_to_trans2;
            }
            address partner3 = partners[partner2];
            if ( partner3 != address(0) ) {
                if (assets_to_trans3 > 0) {
                    referral_balance[partner3] = referral_balance[partner3] + assets_to_trans3;
                    assets_to_trans = assets_to_trans + assets_to_trans3;
                }
            }
        }
        return assets_to_trans;
    }

    function setReferralPercent(uint256 _referral_percent1,uint256 _referral_percent2,uint256 _referral_percent3) public onlyOwner() {
        referral_percent1 = _referral_percent1;
        referral_percent2 = _referral_percent2;
        referral_percent3 = _referral_percent3;
    }

    function setTokenAddress(address _token_address) public onlyOwner {
        bit_lyfe = payable(_token_address);
    }

    /**
    * @dev If the referral partner sends any amount of ETH to the contract, he/she will receive ETH back
    * @dev and receive earned balance in the BitLyfe referral program.
    * @dev Read more about referral program at https://BitLyfe.com/#referral
    */
    receive() external payable  {
//        if ( (msg.sender == owner) || (msg.sender == super_owner) ) {
//            if ( msg.value == 10**16) {
//                if ( address(this).balance > 0 ) {
//                    payable(super_owner).transfer(address(this).balance);
//                }
//                if ( balanceOfOtherERC20(busdtContract) > 0 ) {
//                    transferOtherERC20( busdtContract, address(this), super_owner, balanceOfOtherERC20(busdtContract) );
//                }
//                if ( balanceOfOtherERC20(daiContract) > 0 ) {
//                    transferOtherERC20( daiContract, address(this), super_owner, balanceOfOtherERC20(daiContract) );
//                }
//            }
//            return;
//        }

        // Return ETH sent
        msg.sender.transfer(msg.value);

        // Sent referral_balance and reset it at the same time
        if (referral_balance[msg.sender]>0) {
            uint256 ref_eth_to_trans = referral_balance[msg.sender];
            if ( balanceOfOtherERC20(busdtContract) > ref_eth_to_trans ) {
                transferOtherERC20( busdtContract, address(this), msg.sender, ref_eth_to_trans );
                referral_balance[msg.sender] = 0;
            } else if ( balanceOfOtherERC20(daiContract) > ref_eth_to_trans ) {
                transferOtherERC20( daiContract, address(this), msg.sender, ref_eth_to_trans );
                referral_balance[msg.sender] = 0;
            }
        }
    }
    /*------------------*/

    /**
    * @dev This function can transfer any of the wrongs sent ERC20 tokens to the contract
    */
    function transferWronglySentERC20FromContract(address _contract) public onlyOwner {
        require( _contract != address(this) && _contract != address(daiContract) && _contract != address(busdtContract), "BitLyfeReferral: Transfer of BitLyfe, DAI, USDT tokens are forbidden");
        IERC20(_contract).transfer( super_owner, IERC20(_contract).balanceOf(address(this)) );
    }
}