// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

import "https://github.com/Dexaran/ERC223-token-standard/blob/development/token/ERC223/IERC223.sol";
import "https://github.com/Dexaran/ERC223-token-standard/blob/development/token/ERC223/IERC223Recipient.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract D223Token {

     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string  private _name;
    string  private _symbol;
    uint8   private _decimals;
    uint256 private _totalSupply;
    mapping(address account => mapping(address spender => uint256)) private allowances;
    
    mapping(address => uint256) private balances; // List of user balances.

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
     
    constructor()
    {
        _name     = "Dex223 token";
        _symbol   = "D223";
        _decimals = 18;
        balances[msg.sender] = 80000000 * 1e18;
        _totalSupply = 80000000 * 1e18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC223} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC223-balanceOf} and {IERC223-transfer}.
     */
    function decimals() public view returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev See {IERC223-totalSupply}.
     */
    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev See {IERC223-standard}.
     */
    function standard() public view returns (string memory)
    {
        return "223";
    }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public view returns (uint256)
    {
        return balances[_owner];
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes calldata _data) public returns (bool success)
    {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public returns (bool success)
    {
        bytes memory _empty = hex"00000000";
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _empty);
        }
        emit Transfer(msg.sender, _to, _value, _empty);
        return true;
    }

    // ERC-20 functions for backwards compatibility.

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {

        // Safety checks.
        require(_spender != address(0), "ERC-223: Spender error.");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        
        require(allowances[_from][msg.sender] >= _value, "ERC-223: Insufficient allowance.");
        
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(_from, _to, _value, hex"00000000");
        
        return true;
    }
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract D223ICO {

    address public owner = msg.sender;

    uint256 public price_rate_USD = 2500; // Target price $0.0004 per D223 token.
    uint256 public price_rate_ETH   = price_rate_USD * 2000; // Target price $0.0004 per D223 token.

    address public USDT_contract  = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC_contract  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI_contract   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ICO_token      = 0xf5717D6c1cbAFE00A4c800B227eCe496180244F9;

    receive() external payable
    {
        IERC20(ICO_token).transfer(msg.sender, msg.value * price_rate_ETH);
    }

    function tokenReceived(address _from, uint _value, bytes memory _data) public returns (bytes4)
    {
        require(msg.sender == ICO_token);
        return this.tokenReceived.selector; //return 0x8943ec02;
    }

    function purchaseTokens(address _payment_token, uint256 _payment_amount) public
    {
        require(_payment_token == USDT_contract || _payment_token == USDC_contract || _payment_token == DAI_contract, "Wrong token");
        safeTransferFrom(_payment_token, msg.sender, address(this), _payment_amount);
        IERC20(ICO_token).transfer(msg.sender, _payment_amount * price_rate_USD);
    }

    function getRewardAmount(address _payment_token, uint256 _deposit) public view returns (uint256)
    {
        if(_payment_token == USDT_contract || _payment_token == USDC_contract || _payment_token == DAI_contract) return _deposit * price_rate_USD;
        if(_payment_token == address(0))     return _deposit * price_rate_USD * price_rate_ETH;
        return 0;
    }

    function set(uint256 _price_USD, uint256 _price_rate_ETH, address _ICO_token, address _USDT, address _USDC, address _DAI) public
    {
        require(msg.sender == owner);
        price_rate_USD     = _price_USD;
        USDT_contract      = _USDT;
        USDC_contract      = _USDC;
        DAI_contract       = _DAI;
        ICO_token          = _ICO_token;
        price_rate_ETH     = _price_rate_ETH;
    }

    function updateETH(uint256 _price_rate_ETH) external 
    {
        require(msg.sender == owner);
        price_rate_ETH     = _price_rate_ETH;
    }

    function extractTokens(address _token, uint256 _amount) public
    {
        require(msg.sender == owner);
        IERC20(_token).transfer(msg.sender, _amount);
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }
}
