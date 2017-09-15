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

    address     public owner; // temporary address
    address     public privilegedAccount;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assert(msg.sender == owner);
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
    bool        public crowdFundingLaunched;
    bool        public hotWalletSet;
    TableCoin   public tokenReward;
    address     public hotWallet;

    event LaunchCrowdFund(bool launched);
    event FundTransfer(address _backer, uint256 _amount, bool didContribute);
    event HotWalletSet(bool set);
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) ethBalances;

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

    function CrowdFund(address _tokenContractAddress) {
        tokenContractAddress = _tokenContractAddress;
        tokenReward = TableCoin(tokenContractAddress);
        crowdFundFrozen = true;
        hotWalletSet = false;
    }

    // 1st step in deployment
    function setHotWallet(address _hotWallet) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        hotWallet = _hotWallet;
        hotWalletSet = true;
        HotWalletSet(true);
        return true;
    }

    function stopCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        assert(tokensLeft == 0);
        crowdFundFrozen = true;
        return true;
    }

    function startCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        assert(tokensLeft > 0);
        crowdFundFrozen = false;
        return true;
    }
    
    // 2nd step in deployment, starts crowdfund
    function setCrowdFundReserve(uint256 _amount) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        assert(hotWalletSet);
        require(_amount > 0);
        crowdFundReserve = _amount;
        tokensLeft = crowdFundReserve;
        crowdFundFrozen = false;
        crowdFundingLaunched = true;
        balances[this] = crowdFundReserve;
        LaunchCrowdFund(true);
        return true;
    }

    // Used when someone needs to collect a refund
    function safeWithdrawEth() payable {
        assert(ethBalances[msg.sender] > 0);
        require(msg.value == 0);
        address addrToRefund = msg.sender;
        uint256 amountRefund = ethBalances[msg.sender];
        ethBalances[msg.sender] = 0;
        if (addrToRefund.call.value(amountRefund)()) {
        } else {
            revert();
        }
    }

    // low level purchase function
    function tokenPurchase(address beneficiary) payable {
        assert(!crowdFundFrozen);
        assert(tokensLeft > 0);
        require(beneficiary != 0x0);
        require(msg.value > 0);
        require(msg.value >= tokenCostInWei);
        uint256 _amountTBCReceive = div(msg.value, tokenCostInWei);
        // calculates the amount of tokens to receive in wei
        uint256 amountTBCReceive = mul(_amountTBCReceive, 1 ether);
        uint256 amountCharged;
        uint256 amountRefund;
        // checks to see if backer is trying to buy more than the available supply of tokens
        if (amountTBCReceive >= tokensLeft) {
            amountTBCReceive = tokensLeft;
            uint256 _amountCharged = mul(amountTBCReceive, tokenCostInWei);
            amountCharged = div(_amountCharged, 1 ether);
            amountRefund = msg.value - amountCharged;
        } else {
            amountCharged = msg.value;
            amountRefund = 0;
        }
        balances[beneficiary] = safeAdd(balances[beneficiary], amountTBCReceive);
        balances[this] = safeSub(balances[this], amountTBCReceive);
        tokensBought = safeAdd(tokensBought, amountTBCReceive);
        tokensLeft = safeSub(tokensLeft, amountTBCReceive);
        if (tokensLeft == 0) {
            crowdFundFrozen = true;
        }
        crowdFundReserve = safeSub(crowdFundReserve, amountTBCReceive);
        if (tokenReward.transfer(beneficiary, amountTBCReceive)) {
            FundTransfer(beneficiary, amountTBCReceive, true);
            hotWallet.transfer(amountCharged);
            if (amountRefund > 0) {
                // this forces the user to manually withdraw any additional ethereum
                ethBalances[beneficiary] = safeAdd(ethBalances[beneficiary], amountRefund);
            }
        } else {
            revert();
        }  
    }

    // Fallback Function
    // Used to trigger purchasing of tokens
    function() payable {
        tokenPurchase(msg.sender);
    }
}