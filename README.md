# TableCoin

TableCoin repository

# Variables that need to be set before deployment:
* Presale:
    * Funding goal in ethereum

# Information Needed before deployment:
* Presale:
    * Total number of tokens to be available (must convert to units of wei when entering the information)
    * Duration of presale in minutes (DO NOT convert to units of wei, if you want 60 minutes enter 60, 90 minutes enter 90, etc....)
* Crowdfund:
    * Initial number of tokens to be available (must convert  to units of wei when entering the information

# Deployment steps (PRESALE)
* 1) Deploy TableCoin.sol
* 2) Deploy presale.sol (provide address of token contract, and duration of presale in minutes)
* 3) Execute the 'setHotWallet' function of presale.sol
* 4) Send the amount of tokens available in the presale to the presale contract address
* 5) Go to https://etherconverter.online/ and enter in the number of tokens available in the presale into the "Ether" text field.
* 6) Copy the data from the "Wei" text field, and while executing the 'setCrowdFundReserve' function, enter that data into the 'amount' field. This will then set the balance of the smart contract, and launch the presale.

# Deployment steps (crowdfund)
* 1) Deploy the crowdFund.sol smart contract providing the address of the token contract
* 2) Execute the 'setHotWallet' function of crowdFund.sol
* 3) Execute the 'setCrowdFundReserve' function of crowdFund.sol, providing the total number of tokens available in the crowdFund (follow the same steps 5+6 from the presale deployment) this will then launch the crowdfund.





# How to log fiat contributions (must be done from owner or privileged account)
* 1) Execute the 'Log Fiat Contribution' function, providing the email of the backer, and the amount of tokens they bought converted into units of wei.
* NOTE: Until the contribution is withdrawn, you can enter the sha256 hash of the email address into the 'fiat contribution balances' box of the contract admin page to retrieve the TAC balance of that backer.

# How to withdraw fiat contributions (must be done from owner or privileged account)
* 1) Execute the 'Withdraw Fiat Contribution Rewards' function, providing the email of the backer, and their destination ethereum address for the TAC to be stored in. The destination addrress can't be the owner, or the privileged account address