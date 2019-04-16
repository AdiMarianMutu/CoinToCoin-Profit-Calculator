# CoinToCoin Profit Calculator
A simple and fast profit calculator to get % profits from cryptocurrencies swap

## How to use

Just save or download the PowerShell script (click [here](https://github.com/Xxshark888xX/CoinToCoin-Profit-Calculator/blob/master/CoinToCoinProfitCalculator_run.ps1) to get it), right click on it and 'Run with PowerShell' then follow the on-screen instructions.

([PowerShell v5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) minimum required)

## Found a bug?

If you find a bug please send me an e-mail to **mutu.adi.marian@gmail.com** (most of the time the script will give you an error on-screen, please attach it with the e-mail)

## How does work?

The script uses [CryptoCompare's API](https://min-api.cryptocompare.com/) to connect to an exchange choose by you.<br>
Keep in mind to verify that the chosen exchange has the coin pair you want to get the informations about.<br>
As example [Kraken](https://www.kraken.com) exchange doesn't have the pair for DGB-LTC, but don't worry, the script will give you a clear error if this will happen.<br>
You can get a list with all the exchanges and respective coin pair [here](https://min-api.cryptocompare.com/data/v2/all/exchanges) (the list is in json format)

## Interface

![Alt Text](https://i.imgur.com/OGXRVAv.png)

### {Overall Informations}

**Profit Difference Since (PDS)**:
  Calculates the *time passed* from the *last* time you *executed* the script, is calculated in *days*, *hours*, *minutes* and *seconds* passed.
  
  Example: Total profit: +1.01% (PDS: -17.89%) - The PDS is of 13 seconds, this means that in 13 seconds my total profit decreased of 17.89%, so 13 seconds before my total profit was of +1.19%.
  
**Original value**:
  75000 DGB ([DigiByte](https://digibyte.io/)) - This is your total investment, is calculated by increasing the original value of every individual investment.
  
  Example: 25k DGB ([DigiByte](https://digibyte.io/)) (swapped for 4.9811 LTC) + 30k DGB ([DigiByte](https://digibyte.io/)) (swapped for 6018.8068 RVN) + 20k DGB ([DigiByte](https://digibyte.io/)) (swapped for 17938.5876 IOTX) = 75k DGB ([DigiByte](https://digibyte.io/)) swapped
  
**Current value**

  75759.9221 DGB ([DigiByte](https://digibyte.io/)) => 744.34 GBP PDS: -0.28% - This means that if I'll swap back all the coins to DGB ([DigiByte](https://digibyte.io/)) I'll get a **gross** profit of 759.9221 DGB ([DigiByte](https://digibyte.io/)) (+1.01%). And their value into the chosen fiat will be of 744.34 GBP (+-) and the PDS of 13 seconds for the current value into the chosen fiat decreased of 0.28%
  
### {Individual Swaps}

  Same rules from the *Overall Informations* sections applies also here
  
  
## I wrote this script just because I do a lot of coin swaps trading to get back the profits in DGB ([DigiByte](https://digibyte.io/)) and I needed an automatic process that suited my needs.



### This script is 100% free and open source without a license, use at your own risk! (*I'm not giving financial advice*)
