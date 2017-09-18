# TableCoin

TableCoin repository


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
