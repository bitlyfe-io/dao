pragma solidity 0.6.11; // 5ef660b1

/* Abstract contracts */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
import "./Pangolin.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/**
 * @title ERC20 interface with allowance
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
	uint public _totalSupply;
	uint public decimals;
	function totalSupply() public view virtual returns (uint);
	function balanceOf(address who) public view virtual returns (uint);
	function transfer(address to, uint value) virtual public returns (bool);
	function allowance(address owner, address spender) public view virtual returns (uint);
	function transferFrom(address from, address to, uint value) virtual public returns (bool);
	function approve(address spender, uint value) virtual public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title Implementation of the basic standard ERC20 token.
 * @dev ERC20 with allowance
 */
abstract contract StandardToken is ERC20 {
	using SafeMath for uint;
	mapping(address => uint) public balances;
	mapping (address => mapping (address => uint)) public allowed;

	/**
    * @dev Fix for the ERC20 short address attack.
    */
	function totalSupply() public view override virtual returns (uint) {
		return _totalSupply;
	}

	/**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
	function transfer(address _to, uint _value) override virtual public returns (bool) {
		require( balances[msg.sender] >= _value, "Not enough amount on the source address");
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
    * @dev Get the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
	function balanceOf(address _owner) view override public returns (uint balance) {
		return balances[_owner];
	}

	/**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
	function transferFrom(address _from, address _to, uint _value) override virtual public returns (bool) {
		uint _allowance = allowed[_from][msg.sender];
		if (_from != msg.sender && _allowance != uint(-1)) {
			require(_allowance>=_value,"Not enough allowed amount");
			allowed[_from][msg.sender] = _allowance.sub(_value);
		}
		require( balances[_from] >= _value, "Not enough amount on the source address");
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
	function approve(address _spender, uint _value) override public returns(bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return remaining A uint specifying the amount of tokens still available for the spender.
    */
	function allowance(address _owner, address _spender) override public view returns (uint remaining) {
		return allowed[_owner][_spender];
	}

}

/**
 * @dev Abstract contract of BitLyfe
 */
abstract contract BitLyfeOnIssue {
	function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public virtual returns(uint256);
}

abstract contract BitLyfeOnBurn {
	function onBurnTokens(address _issuer, address _partner, uint256 _tokens_to_burn, uint256 _burning_price, uint256 _asset_amount) public virtual returns(uint256);
}

abstract contract abstractBitLyfeAssetsBalancer {
	function autoBalancing() public virtual returns(bool);
}
/* END of: Abstract contracts */


abstract contract LinkedToStableCoins {
	using SafeERC20 for IERC20;
	// Fixed point math factor is 10^8
	uint256 constant public fmkd = 8;
	uint256 constant public fmk = 10**fmkd;
	uint256 constant internal _decimals = 8;
	address constant internal super_owner = 0x1258f072cb913c42fcbad66cbd0e0d099d5e1d4f;
	address internal owner;

	address public usdtContract;
	address public daiContract;

	function balanceOfOtherERC20( address _token ) internal view returns (uint256) {
		if ( _token == address(0x0) ) return 0;
		return tokenAmountToFixedAmount( _token, IERC20(_token).balanceOf(address(this)) );
	}

	function balanceOfOtherERC20AtAddress( address _token, address _address ) internal view returns (uint256) {
		if ( _token == address(0x0) ) return 0;
		return tokenAmountToFixedAmount( _token, IERC20(_token).balanceOf(_address) );
	}

	function transferOtherERC20( address _token, address _from, address _to, uint256 _amount ) internal returns (bool) {
		if ( _token == address(0x0) ) return false;
		if ( _from == address(this) ) {
			IERC20(_token).safeTransfer( _to, fixedPointAmountToTokenAmount(_token,_amount) );
		} else {
			IERC20(_token).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(_token,_amount) );
		}
		return true;
	}

	function transferAmountOfAnyAsset( address _from, address _to, uint256 _amount ) internal returns (bool) {
		uint256 amount = _amount;
		uint256 usdtBal = balanceOfOtherERC20AtAddress(usdtContract,_from);
		uint256 daiBal = balanceOfOtherERC20AtAddress(daiContract,_from);
		require( ( usdtBal + daiBal ) >= _amount, "Not enough amount of assets");
		if ( _from == address(this) ) {
			if ( usdtBal >= amount ) {
				IERC20(usdtContract).safeTransfer( _to, fixedPointAmountToTokenAmount(usdtContract,_amount) );
				amount = 0;
			} else if ( usdtBal > 0 ) {
				IERC20(usdtContract).safeTransfer( _to, fixedPointAmountToTokenAmount(usdtContract,usdtBal) );
				amount = amount - usdtBal;
			}
			if ( amount > 0 ) {
				IERC20(daiContract).safeTransfer( _to, fixedPointAmountToTokenAmount(daiContract,_amount) );
			}
		} else {
			if ( usdtBal >= amount ) {
				IERC20(usdtContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(usdtContract,_amount) );
				amount = 0;
			} else if ( usdtBal > 0 ) {
				IERC20(usdtContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(usdtContract,usdtBal) );
				amount = amount - usdtBal;
			}
			if ( amount > 0 ) {
				IERC20(daiContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(daiContract,_amount) );
			}
		}
		return true;
	}

	function fixedPointAmountToTokenAmount( address _token, uint256 _amount ) internal view returns (uint256) {
		uint dt = IERC20(_token).decimals();
		uint256 amount = 0;
		if ( dt > _decimals ) {
			amount = _amount * 10**(dt-_decimals);
		} else {
			amount = _amount / 10**(_decimals-dt);
		}
		return amount;
	}

	function tokenAmountToFixedAmount( address _token, uint256 _amount ) internal view returns (uint256) {
		uint dt = IERC20(_token).decimals();
		uint256 amount = 0;
		if ( dt > _decimals ) {
			amount = _amount / 10**(dt-_decimals);
		} else {
			amount = _amount * 10**(_decimals-dt);
		}
		return amount;
	}

	function collateral() public view returns (uint256) {
		if ( usdtContract == daiContract ) {
			return balanceOfOtherERC20(usdtContract);
		} else {
			return balanceOfOtherERC20(usdtContract) + balanceOfOtherERC20(daiContract);
		}
	}

	function setUSDTContract(address _usdtContract) public onlyOwner {
		usdtContract = _usdtContract;
	}

	function setDAIContract(address _daiContract) public onlyOwner {
		daiContract = _daiContract;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner), "You don't have permissions to call it" );
		_;
	}

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @title BitLyfe
 * @dev BitLyfe token contract
 */
contract BitLyfe is LinkedToStableCoins, StandardToken {
	// Burn price ratio is 0.9
	uint256 constant burn_ratio = 9 * fmk / 10;
	// Burning fee is 5%
	uint256 constant burn_fee = 5 * fmk / 100;
	// Issuing price increase ratio vs locked_amount/supply is 14 %
	uint256 public issue_increase_ratio = 14 * fmk / 100;

	string public name;
	string public symbol;

	uint256 public issue_price;
	uint256 public burn_price;

	// Counters of transactions
	uint256 public issue_counter;
	uint256 public burn_counter;

	// Issued & burned volumes
	uint256 public issued_volume;
	uint256 public burned_volume;

	// Links to other smart-contracts
	address referralProgramContract;
	address bonusProgramContract;
	address pangolinRouter;

	// Contract for assets balancing
	address assetsBalancer;

	/**
    * @dev constructor, initialization of starting values
    */
	constructor() public {
		name = "BitLyfe DAO";
		symbol = "BitLyfe";
		decimals = _decimals;

		owner = msg.sender;

		// Initial Supply of BitLyfe is ZERO
		_totalSupply = 0;
		balances[address(this)] = _totalSupply;

		// Initial issue price of BitLyfe is 1 USDT or DAI per 1.0 BitLyfe
		issue_price = 1 * fmk;

		// USDT token contract address
		usdtContract = 0xde3A24028580884448a5397872046a019649b084;
		// DAI token contract address
		daiContract = 0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a;
		// Pangolin V2 Router
		pangolinRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
	}

	function issuePrice() public view returns (uint256) {
		return issue_price;
	}

	function burnPrice() public view returns (uint256) {
		return burn_price;
	}

	/**
    * @dev ERC20 transfer with burning of BitLyfe when it's sent to BitLyfe smart-contract
    */
	function transfer(address _to, uint256 _value) public override returns (bool) {
		require(_to != address(0),"Destination address can't be empty");
		require(_value > 0,"Value for transfer should be more than zero");
		return transferFrom( msg.sender, _to, _value);
	}

	/**
    * @dev ERC20 transferFrom with burning of BitLyfe when it will be sent to the BitLyfe smart-contract
    */
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
		require(_to != address(0),"Destination address can't be empty");
		require(_value > 0,"Value for transfer should be more than zero");
		bool res = false;
		if ( _from == msg.sender ) {
			res = super.transfer(_to, _value);
		} else {
			res = super.transferFrom(_from, _to, _value);
		}
		if ( res ) {
			if ( _to == address(this) ) {
				burnBitLyfe( _from, _value );
			}
			return true;
		}
		return false;
	}

	/**
    * @dev Recalc issuing and burning prices
    */
	function recalcPrices() private {
		issue_price = collateral() * fmk / _totalSupply;
		burn_price = issue_price * burn_ratio / fmk;
		issue_price = issue_price + issue_price * issue_increase_ratio / fmk;
	}

	/**
    * @dev Issue the BitLyfe tokens, recalc prices and hold ERC20 USDT or DAI on the smart-contract.
    */
	function issueBitLyfeVsKnownAsset( address _token_contract, address _to_address, uint256 _asset_amount, address _partner, bool _need_transfer ) private returns (uint256) {
		uint256 tokens_to_issue;
		tokens_to_issue = tokenAmountToFixedAmount( _token_contract, _asset_amount ) * fmk / issue_price;
		if ( _need_transfer ) {
			require( IERC20(_token_contract).allowance(_to_address,address(this)) >= _asset_amount, "issueBitLyfeForERC20: Not enough allowance" );
			uint256 asset_balance_before = IERC20(_token_contract).balanceOf(address(this));
			IERC20(_token_contract).safeTransferFrom(_to_address,address(this),_asset_amount);
			require( IERC20(_token_contract).balanceOf(address(this)) == (asset_balance_before+_asset_amount), "issueBitLyfeForERC20: Error in transferring" );
		}
		if (address(referralProgramContract) != address(0) && _partner != address(0)) {
			BitLyfeOnIssue(referralProgramContract).onIssueTokens( _to_address, _partner, tokens_to_issue, issue_price, tokenAmountToFixedAmount(_token_contract,_asset_amount) );
		}
		// Increase the total supply
		_totalSupply = _totalSupply.add( tokens_to_issue );
		balances[_to_address] = balances[_to_address].add( tokens_to_issue );
		if ( address(bonusProgramContract) != address(0) ) {
			uint256 to_bonus_amount = BitLyfeOnIssue(bonusProgramContract).onIssueTokens( _to_address, _partner, tokens_to_issue, issue_price, tokenAmountToFixedAmount(_token_contract,_asset_amount) );
			if (to_bonus_amount > 0) {
				if ( ( _token_contract == usdtContract ) || ( balanceOfOtherERC20(usdtContract) >= to_bonus_amount ) ) {
					transferOtherERC20( usdtContract, address(this), bonusProgramContract, to_bonus_amount );
				} else {
					transferOtherERC20( daiContract, address(this), bonusProgramContract, to_bonus_amount );
				}
			}
		}
		if (  address(assetsBalancer) != address(0) && ( _asset_amount - (_asset_amount/1000)*1000) == 777 ) {
			abstractBitLyfeAssetsBalancer( assetsBalancer ).autoBalancing();
		}
		// Recalculate issuing & burning prices after tokens issue
		recalcPrices();
		//---------------------------------
		emit Transfer(address(0x0), address(this), tokens_to_issue);
		emit Transfer(address(this), _to_address, tokens_to_issue);
		issue_counter++;
		issued_volume = issued_volume + tokens_to_issue;
		log3(bytes20(address(this)),bytes8("ISSUE"),bytes32(_totalSupply),bytes32( (issue_price<<128) | burn_price ));
		return tokens_to_issue;
	}

	function issueBitLyfeVsERC20( address _erc20_contract, uint256 _max_slippage, uint256 _deadline, uint256 _erc20_asset_amount, address _partner) public returns (uint256){
		require( _deadline == 0 || block.timestamp <= _deadline, "issueBitLyfeERC20: reverted because time is over" );
		// Before issuing from USDT or DAI contracts you need to call approve(BITLYFE_CONTRACT_ADDRESS, AMOUNT) from your wallet
		if ( _erc20_contract == usdtContract || _erc20_contract == daiContract ) {
			return issueBitLyfeVsKnownAsset( _erc20_contract, msg.sender, _erc20_asset_amount, _partner, true );
		}
		// Default slippage of swap through Pangolin is 2%
		if ( _max_slippage == 0 ) _max_slippage = 20;
		IERC20(_erc20_contract).safeTransferFrom(msg.sender,address(this),_erc20_asset_amount);
		IERC20(_erc20_contract).safeIncreaseAllowance(pangolinRouter,_erc20_asset_amount);
		address[] memory path;
		if ( _erc20_contract == IPangolinRouter(pangolinRouter).WAVAX() ) {
			// Direct swap WAVAX -> DAI if _erc20_contract is WAVAX contract
			path = new address[](2);
			path[0] = IPangolinRouter(pangolinRouter).WAVAX();
			path[1] = daiContract;
		} else {
			// Using path ERC20 -> WAVAX -> DAI because most of liquidity in pairs with ETH
			// and resulted amount of DAI tokens will be greater than in direct pair
			path = new address[](3);
			path[0] = _erc20_contract;
			path[1] = IPangolinRouter(pangolinRouter).WAVAX();
			path[2] = daiContract;
		}
		uint[] memory amounts = IPangolinRouter(pangolinRouter).getAmountsOut(_erc20_asset_amount,path);
		uint256 out_min_amount = amounts[path.length-1] * _max_slippage / 1000;
		amounts = IPangolinRouter(pangolinRouter).swapExactTokensForTokens(_erc20_asset_amount, out_min_amount, path, address(this), block.timestamp);
		return issueBitLyfeVsKnownAsset( daiContract, msg.sender, amounts[path.length-1], _partner, false );
	}

	/**
    * @dev Burn the BitLyfe tokens when someone sends BitLyfe to the BitLyfe token smart-contract.
    */
	function burnBitLyfeToERC20Private(address _erc20_contract, address _from_address, uint256 _tokens_to_burn) private returns (bool){
		require( _totalSupply >= _tokens_to_burn, "Not enough supply to burn");
		require( _tokens_to_burn >= 1000, "Minimum amount of BitLyfe to burn is 0.00001 BitLyfe" );
		uint256 contract_balance = collateral();
		uint256 assets_to_send = _tokens_to_burn * burn_price / fmk;
		require( ( contract_balance + 10000 ) >= assets_to_send, "Not enough collateral on the contract to burn tokens" );
		if ( assets_to_send > contract_balance ) {
			assets_to_send = contract_balance;
		}
		uint256 fees_of_burn = assets_to_send * burn_fee / fmk;
		// Decrease the total supply
		_totalSupply = _totalSupply.sub(_tokens_to_burn);
		uint256 usdt_to_send = assets_to_send-fees_of_burn;
		uint256 usdtBal = balanceOfOtherERC20( usdtContract );
		if ( _erc20_contract == usdtContract || _erc20_contract == daiContract ) {
			if ( usdtBal >= usdt_to_send ) {
				transferOtherERC20( usdtContract, address(this), _from_address, usdt_to_send );
				usdt_to_send = 0;
			} else if ( usdtBal  >= 0 ) {
				transferOtherERC20( usdtContract, address(this), _from_address, usdtBal );
				usdt_to_send = usdt_to_send - usdtBal;
			}
			if ( usdt_to_send > 0 ) {
				transferOtherERC20( daiContract, address(this), _from_address, usdt_to_send );
			}
		} else {
			require( usdtBal >= usdt_to_send, "Not enough USDT on the BitLyfe contract, need to call balancing of the assets or burn to USDT,DAI");
			usdt_to_send = fixedPointAmountToTokenAmount(usdtContract,usdt_to_send);
			address[] memory path;
			if ( IPangolinRouter(pangolinRouter).WAVAX() == _erc20_contract ) {
				path = new address[](2);
				path[0] = usdtContract;
				path[1] = IPangolinRouter(pangolinRouter).WAVAX();
			} else {
				path = new address[](3);
				path[0] = usdtContract;
				path[1] = IPangolinRouter(pangolinRouter).WAVAX();
				path[2] = _erc20_contract;
			}
			IERC20(usdtContract).safeIncreaseAllowance(pangolinRouter,usdt_to_send);
			uint[] memory amounts = IPangolinRouter(pangolinRouter).getAmountsOut(usdt_to_send, path);
			IPangolinRouter(pangolinRouter).swapExactTokensForTokens(usdt_to_send, amounts[amounts.length-1] * 98/100, path, _from_address, block.timestamp);
		}
		transferOtherERC20( daiContract, address(this), owner, fees_of_burn );
		contract_balance = contract_balance.sub( assets_to_send );
		balances[address(this)] = balances[address(this)].sub( _tokens_to_burn );
		if ( _totalSupply == 0 ) {
			// If all tokens were burnt 🙂
			burn_price = 0;
			if ( balanceOfOtherERC20( usdtContract ) > 0 ) {
				IERC20(usdtContract).safeTransfer( owner, balanceOfOtherERC20( usdtContract ) );
			}
			if ( balanceOfOtherERC20( daiContract ) > 0 ) {
				IERC20(daiContract).safeTransfer( owner, balanceOfOtherERC20( daiContract ) );
			}
		} else {
			// Recalculate issuing & burning prices after the burning
			recalcPrices();
		}
		emit Transfer(address(this), address(0x0), _tokens_to_burn);
		burn_counter++;
		burned_volume = burned_volume + _tokens_to_burn;
		log3(bytes20(address(this)),bytes4("BURN"),bytes32(_totalSupply),bytes32( (issue_price<<128) | burn_price ));
		return true;
	}

	function burnBitLyfe(address _from_address, uint256 _tokens_to_burn) private returns (bool){
		return burnBitLyfeToERC20Private(usdtContract, _from_address, _tokens_to_burn);
	}

	function burnBitLyfeToERC20(address _erc20_contract, uint256 _tokens_to_burn) public returns (bool){
		require(balances[msg.sender] >= _tokens_to_burn, "Not enough BitLyfe balance to burn");
		balances[msg.sender] = balances[msg.sender].sub(_tokens_to_burn);
		balances[address(this)] = balances[address(this)].add(_tokens_to_burn);
		emit Transfer( msg.sender, address(this), _tokens_to_burn );
		return burnBitLyfeToERC20Private(_erc20_contract, msg.sender, _tokens_to_burn);
	}

	receive() external payable  {
		msg.sender.transfer(msg.value);
	}

	function setOptionsContract(address _optionsContract, bool _enabled) public onlyOwner() {
		optionsContracts[_optionsContract] = _enabled;
	}

	function setReferralProgramContract(address _referralProgramContract) public onlyOwner() {
		referralProgramContract = _referralProgramContract;
	}

	function setBonusContract(address _bonusProgramContract) public onlyOwner() {
		bonusProgramContract = _bonusProgramContract;
	}

	function setAssetsBalancer(address _assetsBalancer) public onlyOwner() {
		assetsBalancer = _assetsBalancer;
		// Allow to balancer contract make swap between assets
		if ( IERC20(usdtContract).allowance(address(this),assetsBalancer) == 0 ) {
			IERC20(usdtContract).safeIncreaseAllowance(assetsBalancer,uint(-1));
		}
		if ( IERC20(daiContract).allowance(address(this),assetsBalancer) == 0 ) {
			IERC20(daiContract).safeIncreaseAllowance(assetsBalancer,uint(-1));
		}
	}

	function setPangolinRouter(address _pangolinRouter) public onlyOwner() {
		pangolinRouter = _pangolinRouter;
	}
}
// SPDX-License-Identifier: UNLICENSED