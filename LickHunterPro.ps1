$binanceprofit = "$PSScriptRoot\Binance\binanceProfit"
$binancewebsocket = "$PSScriptRoot\Binance\binanceWebsocket"

#Stop bot if running
if ((Get-Process binanceWebsocket -ErrorAction SilentlyContinue) -or (Get-Process binanceProfit -ErrorAction SilentlyContinue)) {
pm2.cmd delete "$binancewebsocket\binanceWebsocket.exe"
pm2.cmd delete "$binanceprofit\binanceProfit.exe"
pm2.cmd save
Stop-Process -Name cmd
Stop-Process -Name node
}

#Start bot
Copy-Item "$PSScriptRoot\settings-binance.py" "$binancewebsocket\settings.py" -Force
Copy-Item "$PSScriptRoot\settings-binance.py" "$binanceprofit\settings.py" -Force
pm2.cmd start "$binancewebsocket\binanceWebsocket.exe"
pm2.cmd start "$binanceprofit\binanceProfit.exe"
pm2.cmd save
Start-Process cmd -ArgumentList "/c pm2 monit"