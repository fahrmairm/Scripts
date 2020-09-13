$exchange1 = "Binance"
$exchange2 = "Bybit"
$date = Get-Date -Format yyyyMMddhhmm
$settingsbackup = "Settings-Backup"

Add-Type -AssemblyName PresentationFramework

#Run bot if installed
if ((Test-Path .\$exchange1) -xor (Test-Path .\$exchange2)) {
    $exchange = (Get-ChildItem $PSScriptRoot | Where-Object {$_.Name -eq "Binance" -or $_.Name -eq "Bybit"}).Name
    $websocket = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Websocket"}).Name
    $websocketpath = "$PSScriptRoot\$exchange\$websocket"
    $profit = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Profit"}).Name
    $profitpath = "$PSScriptRoot\$exchange\$profit"    
    $original = (Get-Item $PSScriptRoot\settings-$exchange.py).LastWriteTime
    $backup = (Get-Item $PSScriptRoot\$settingsbackup\*-settings-$exchange.py -ErrorAction SilentlyContinue | Select-Object -Last 1).LastWriteTime
        
    #Stop bot if running
    if ((Get-Process $websocket -ErrorAction SilentlyContinue) -or (Get-Process $profit -ErrorAction SilentlyContinue)) {
        pm2.cmd delete "$websocketpath\$websocket.exe"
        pm2.cmd delete "$profitpath\$profit.exe"
        pm2.cmd save
        Stop-Process -Name cmd
        Stop-Process -Name node
        }
    
    #Test if settings.py backup path exist and if false create it
    if (-not (Test-Path $PSScriptRoot\$settingsbackup)) { 
        New-Item -Path $PSScriptRoot -Name $settingsbackup -ItemType Directory -Force
    }
    
    #Check if settings.py has been altered and if true make backup
    if ($original -ne $backup) {
        Copy-Item "$PSScriptRoot\settings-$exchange.py" "$PSScriptRoot\$settingsbackup\$date-settings-$exchange.py" -Recurse
    }

    Copy-Item "$PSScriptRoot\settings-$exchange.py" "$websocketpath\settings.py" -Force
    Copy-Item "$PSScriptRoot\settings-$exchange.py" "$profitpath\settings.py" -Force
    pm2.cmd start "$websocketpath\$websocket.exe"
    pm2.cmd start "$profitpath\$profit.exe"
    pm2.cmd save
    Start-Process cmd -ArgumentList "/c pm2 monit"
}

#Request to install
else {
    $notinstalledmsg = "LickHunter Pro is not installed, please run Install-LickHunterPro.ps1"
    [System.Windows.MessageBox]::Show($notinstalledmsg)
}