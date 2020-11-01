$binanceprofit = "$PSScriptRoot\Binance\binanceProfit"
$binancewebsocket = "$PSScriptRoot\Binance\binanceWebsocket"

#Stop bot if running
pm2.cmd delete "$binancewebsocket\binanceWebsocket.exe"
pm2.cmd delete "$binanceprofit\binanceProfit.exe"
pm2.cmd save
Stop-Process -Name cmd
Stop-Process -Name node