$exchange = (Get-ChildItem $PSScriptRoot | Where-Object {$_.Name -eq "Binance" -or $_.Name -eq "Bybit"}).Name
$websocket = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Websocket"}).Name
$websocketpath = "$PSScriptRoot\$exchange\$websocket"
$profit = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Profit"}).Name
$profitpath = "$PSScriptRoot\$exchange\$profit"
Add-Type -AssemblyName PresentationFramework

#Stop bot if running
if ((Get-Process $websocket -ErrorAction SilentlyContinue) -or (Get-Process $profit -ErrorAction SilentlyContinue)) {
pm2.cmd delete "$websocketpath\$websocket.exe"
pm2.cmd delete "$profitpath\$profit.exe"
pm2.cmd save
Stop-Process -Name cmd
Stop-Process -Name node
}
else {
    [System.Windows.MessageBox]::Show('Lick Hunter Pro for Binance is not running!')
}