pragma solidity 0.4.13;



contract TableCoin {

    // 100,000 in wei
    uint256 public crowdFundReserveAmount = 100000000000000000000000;

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
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) onlyOwner returns (bool success) {
        require(_newOwner != owner);
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


contract Presale is SafeMath, Owned {

    uint256     public tokenCostInWei = 3000000000000000;
    uint256     public fundingGoalInEther;
    uint256     public crowdFundReserve = 0;
    uint256     public tokensBought;
    uint256     public tokensLeft;
    uint256     public presaleDeadline;
    uint256     public presaleDurationInMinutes = 0; // not factored for wei;
    address     public tokenContractAddress;
    address     public hotWallet;
    bool        public crowdFundFrozen;
    bool        public crowdFundingLaunched;
    bool        public hotWalletSet;
    TableCoin   public tokenReward;

    event LaunchCrowdFund(bool launched);
    event FundTransfer(address _backer, uint256 _amount, bool didContribute);
    event TokenWithdrawal(address _to, uint256 _amount, bool withdrawn);
    event HotWalletSet(bool set);
    event PresaleDurationSet(bool set);

    mapping (address => uint256) public balances;
    mapping (address => uint256) ethBalances;


    modifier onlyBeforeCrowdFundStart() {
        require(crowdFundFrozen);
        _;
    }

    modifier onlyAfterCrowdFundingLaunch() {
        require(crowdFundingLaunched);
        _;
    }

    function Presale(address _tokenContractAddress, uint256 _presaleDurationInMinutes) {
        tokenContractAddress = _tokenContractAddress;
        tokenReward = TableCoin(tokenContractAddress);
        presaleDurationInMinutes = _presaleDurationInMinutes;
        crowdFundFrozen = true;
    }


    function stopCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        require(now > presaleDeadline);
        require(!crowdFundFrozen);
        crowdFundFrozen = true;
        return true;
    }

    function startCrowdFunding() onlyOwner onlyAfterCrowdFundingLaunch public returns (bool success) {
        require(tokensLeft > 0);
        require(crowdFundFrozen);
        crowdFundFrozen = false;
        return true;
    }

    // @notice used to return any remaining tokens left in the contract after the presale is closed
    function withdrawRemainingTokens() onlyOwner public returns (bool success) {
        require(now > presaleDeadline);
        require(balances[this] > 0);
        uint256 balanceLeft = balances[this];
        balances[this] = 0;
        tokensLeft = 0;
        crowdFundReserve = 0;
        if (!tokenReward.transfer(msg.sender, balanceLeft)) {
            revert();
        }
        TokenWithdrawal(msg.sender, tokensLeft, true);
        return true;
    }

    // 1st step in deployment
    /// @notice Will set the hot wallet address which will contain ethereum raised by the crowdfund
    /// @param _hotWallet Specifies the Hot Wallet Address
    /// @return Whether the operation completed successfully
    function setHotWallet(address _hotWallet) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        require(presaleDurationInMinutes > 0);
        hotWallet = _hotWallet;
        hotWalletSet = true;
        HotWalletSet(true);
        return true;
    }
   
    // 2nd step in deployment, starts crowdfund
    /// @notice Used to set the amount of tokens in the contract reserve, and launches the crowdfunding
    /// @param _amount Specifies the amount of tokens that are in the contract reserve
    function setCrowdFundReserve(uint256 _amount) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        require(presaleDurationInMinutes > 0);
        require(hotWalletSet);
        require(_amount > 0);
        crowdFundReserve = _amount;
        tokensLeft = crowdFundReserve;
        crowdFundFrozen = false;
        crowdFundingLaunched = true;
        balances[this] = crowdFundReserve;
        presaleDeadline = now + presaleDurationInMinutes * 1 minutes;
        LaunchCrowdFund(true);
        return true;
    }

    /// @notice Used when someone needsd to withdraw ethereum from the contract
    function safeWithdrawEth() {
        require(ethBalances[msg.sender] > 0);
        address addrToRefund = msg.sender;
        uint256 amountRefund = ethBalances[msg.sender];
        ethBalances[msg.sender] = 0;
        if (!addrToRefund.call.value(amountRefund)()) {
            revert();
        }
    }

    // low level purchase function
    /// @param beneficiary this will be set to msg.sender by the contract
    function tokenPurchase(address beneficiary) payable {
        require(!crowdFundFrozen);
        require(presaleDurationInMinutes > 0);
        require(beneficiary != 0x0);
        require(now <= presaleDeadline);
        require(tokensLeft > 0);
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
        crowdFundReserve = safeSub(crowdFundReserve, amountTBCReceive);
        if (tokensLeft == 0) {
            crowdFundFrozen = true;
        }
        require(amountTBCReceive > 0);
        if (tokenReward.transfer(beneficiary, amountTBCReceive)) {
            FundTransfer(beneficiary, amountTBCReceive, true);
            if (!hotWallet.send(amountCharged)) {
                revert();
            }
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
        require(!crowdFundFrozen);
        tokenPurchase(msg.sender);
    }
}