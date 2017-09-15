pragma solidity 0.4.16;



contract TableCoin {

    uint256 public crowdFundReserveAmount;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    mapping (address => uint256) public balances;

    function TableCoin() {
        balances[msg.sender] = crowdFundReserveAmount;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        // msg.sender 
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
    }
}
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


contract CrowdFund is SafeMath, Owned {

    uint256     public tokenCostInWei = 3000000000000000;
    uint256     public fundingGoalInEther;
    uint256     public crowdFundReserve = 0;
    uint256     public tokensBought;
    uint256     public tokensLeft;
    uint256     public presaleDeadline;
    uint256     public startOfPresaleInBlockNumber;
    uint256     public startOfPresaleInMinutes;
    address     public tokenContractAddress;
    bool        public crowdFundFrozen;
    bool        public crowdFundingStopped;
    bool        public crowdFundingLaunched;
    TableCoin   public tokenReward;
    address     public hotWallet;

    event LaunchCrowdFund(bool launched);
    event FundTransfer(address _backer, uint256 _amount, bool didContribute);
    
    mapping (address => uint256) public balances;

    modifier onlyAfterReserveSet() {
        assert(crowdFundReserve > 0);
        _;
    }

    modifier onlyBeforeCrowdFundStart() {
        assert(crowdFundFrozen);
        _;
    }

    modifier onlyAfterCrowdFundingLaunch() {
        assert(crowdFundingLaunched);
        _;
    }

    function CrowdFund() {
        tokenContractAddress = 0x933ef4aA757aA961766c4f451Ac7678dDe40E792;
        tokenReward = TableCoin(tokenContractAddress);
        crowdFundFrozen = true;
        crowdFundingStopped = true;
    }

    // 1st step in deployment
    function setHotWallet(address _hotWallet) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        hotWallet = _hotWallet;
        return true;
    }

    function stopCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        assert(tokensLeft == 0);
        crowdFundingStopped = true;
        return true;
    }

    function startCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        assert(tokensLeft > 0);
        crowdFundingStopped = false;
        return true;
    }
    
    // 2nd step in deployment
    function setCrowdFundReserve(uint256 _amount) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        require(_amount > 0);
        crowdFundReserve = _amount;
        tokensLeft = crowdFundReserve;
        crowdFundFrozen = false;
        crowdFundingStopped = false;
        crowdFundingLaunched = true;
        LaunchCrowdFund(true);
        return true;
    }

    // low level purchase function
    function tokenPurchase() payable {
        assert(!crowdFundFrozen);
        assert(!crowdFundingStopped);
        assert(tokensLeft > 0);
        require(msg.value > 0);
        require(msg.value >= tokenCostInWei);
        uint256 _amountTBCReceive = div(msg.value, tokenCostInWei);
        uint256 amountTBCReceive = mul(_amountTBCReceive, 1 ether);
        uint256 amountCharged;
        // checks to see if backer is trying to buy more than the available supply of tokens
        // for testing we added >=
        if (amountTBCReceive >= tokensLeft) {
            amountTBCReceive = tokensLeft;
            amountCharged = mul(amountTBCReceive,1 ether);
            uint256 amountRefund = msg.value - amountCharged;
        } else {
            amountCharged = msg.value;
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], amountTBCReceive);
        tokensBought = safeAdd(tokensBought, amountTBCReceive);
        tokensLeft = safeSub(tokensLeft, amountTBCReceive);
        if (tokenReward.transfer(msg.sender, amountTBCReceive)) {
            FundTransfer(msg.sender, amountTBCReceive, true);
            hotWallet.transfer(amountCharged);
            if (amountRefund > 0) {
                msg.sender.transfer(amountRefund);
            }
        } else {
            revert();
        }  
    }

    // Fallback Function
    // Used to trigger purchasing of tokens
    function() payable {
        tokenPurchase();
    }
}