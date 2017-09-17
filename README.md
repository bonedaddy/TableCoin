# TableCoin

TableCoin repository


# To Do
* Test TableCoin
* Write crowdFund
* Test crowdFund
* Security Audit
* Test
* Optimize
* Test
* Write Deployment Guide
* Add natspec documentation

# Dev To Do

1) Funding Goal In Ethers need to ber set
2) Add natspec to all solidity files
3) Test out the presale contract
4) Do a security/code review
5) Test
6) Optimize
7) Test


# notes

make token price divisble by a whole number


## DEPLOYMENT ORDER

1)    function setHotWallet(address _hotWallet) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        hotWallet = _hotWallet;
        return true;
    }

2)    function setCrowdFundReserve(uint256 _amount) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        crowdFundReserve = _amount;
        tokensLeft = crowdFundReserve;
        crowdFundFrozen = false;
        LaunchCrowdFund(true);
        return true;
    }
