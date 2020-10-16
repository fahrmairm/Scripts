# LickHunterPro Variable Pairs

On the LickHunterPro Discord a user named Sanduckchan created an overview on the Binance Futures liquidations. You can visit the site @ http://www.lickhunter.com/data/
My script fetches the pairs from the site and places them in the settings.py. The problem was with open orders. When the pairs got replaced you lost track of the open orders. That's why the script also checks your open orders on Binance Futures and combines those pairs with the pairs from the site.

# Features:
- Auto copies **settings.py** to **binanceWebsocket** and **binanceProfit**
- Pairs based on **Top 10 burned by Volume - 24h**, **Top 10 by Liq-Events - 24h**, **Average Liq-Volume in USD - 24h** and **Average Liq-Amount - 24h**
- Set a maximum of traidingpairs
- Set a maximum of open orders, so you don't get too much open orders
- **Open order isolation** When X percent of your wallet balance gets hit by open orders, only the open order pairs will be traded until the percentage drops below X
- Option to not trade latest pairs on Binance Futures, these pairs come from CoinGecko https://www.coingecko.com/en/exchanges/binance_futures and are listed as Unverified Tickers
- Blacklist for pairs you don't want to trade

# Installation:
**You have to have a working LickHunterPro configuration and all settings in settings.py except "pairs =" should be inplace!**
- Place **Start-LickHunterPro-VarPair.ps1** and **LickHunterPro.ps1** in the root of the LickHunterPro folder, in my case C:\LickHunterPro\
- Edit **Start-LickHunter-Pro-VarPair.ps1** with **NotePad++** or **Windows PowerShell ISE**
  - $APIKey = "key" **Set your Binance Futures API key, this can be a read only one**
  - $APISecret = "secret" **Set your Binance Futures API secret**
  - $tradePairs = "1" **Choose 1, 2, 3 or 4, depending what chart your wan't to base your pairs on (1. Top 10 burned by Volume - 24h, 2. Top 10 by Liq-Events - 24h, 3. Average Liq-Volume in USD - 24h, 4. Average Liq-Amount - 24h)**
  - $maxPairs = "8" **The maximum pairs you want to trade, always the top of the chart is used**
  - $maxPositions = "3" **The maximum orders you want to have open at the same time**
  - $openOrderIsolationPercentage = "10" **Only trade open order pairs when X percentage of wallet balance is reached**
  - $whitelist = **Set your personal whitelist of pairs you want to be able to trade**
  - $blacklist = 'BTC','DEFI' **Set your personal blacklist for pairs you don't want to trade**
- Save your changed settings
- **Right-Mouse-Click** on **Start-LickHunterPro-VarPair.ps1** and select **Run with PowerShell**
