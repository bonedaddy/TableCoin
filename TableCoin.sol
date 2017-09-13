pragma solidity 0.4.13;

// Used for function invoke restriction
contract Owned {

    address public owner; // temporary address

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert();
        _; // function code inserted here
    }


    function transferOwnership(address _newOwner) onlyOwner returns (bool success) {
        if (msg.sender != owner)
            revert();
        owner = _newOwner;
        return true;
        
    }

}

contract SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) 
            revert();
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) 
            revert();
        return a - b;
    } 

}

contract TableCoin is SafeMath, Owned {

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    // Balances
    mapping (address => uint256) public balances;

    // Allowance
    mapping (address => mapping (address => uint256)) public allowance;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    // Constructor
    function TableCoin(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }


    //ERC-20 Functions//
    ////////////////////
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_amount > 0);
        require(balances[msg.sender] - _amount >= 0);
        require(balances[_to] + _amount > balances[_to]);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(allowance[_from][msg.sender] > 0);
        require(allowance[_from][msg.sender] - _amount > 0);
        require(balances[_from] - _amount > 0);
        require(balances[_to] + _amount > balances[_to]);
        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;
        Transfer(_from, _to, _amount);
        return true; 
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_amount > 0);
        allowance[msg.sender][_spender] = _amount;
        return true;
    }

    //GETTER Functions//
    function balanceOf(address _person) constant returns (uint256 _amount) {
        return balances[_person];
    }

    function allowance(address _owner, address _spender) constant returns (uint256 _amount) {
        return allowance[_owner][_spender];
    }

    function getTotalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    //ERC-20 Functions//
    ////////////////////

    function() payable {
        require(msg.value == 0);
    }

}