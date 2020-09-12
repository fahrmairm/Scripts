$exchange1 = "Binance"
$exchange2 = "Bybit"
$versionpath = "$PSScriptRoot\Versions"
$date = Get-Date -Format yyyyMMddhhmm
$settingsbackup = "Settings-Backup"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://github.com/CryptoGnome/LickHunterPRO/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$fileName = "Lick.Hunter.Pro.v$version.zip"
$realDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/' + $fileName
$output = "$versionpath\$version\$fileName"

Add-Type -AssemblyName PresentationFramework
Add-Type -Assembly "System.IO.Compression.Filesystem"

#Run bot if installed
if ((Test-Path .\$exchange1) -xor (Test-Path .\$exchange2)) {
    $exchange = (Get-ChildItem $PSScriptRoot | Where-Object {$_.Name -eq "Binance" -or $_.Name -eq "Bybit"}).Name
    $websocket = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Websocket"}).Name
    $websocketpath = "$PSScriptRoot\$exchange\$websocket"
    $profit = (Get-ChildItem $exchange | Where-Object {$_.Name -eq "$($exchange)Profit"}).Name
    $profitpath = "$PSScriptRoot\$exchange\$profit"    
    $original = (Get-Item $PSScriptRoot\settings-$exchange.py).LastWriteTime
    $backup = (Get-Item $PSScriptRoot\$settingsbackup\*-settings-$exchange.py -ErrorAction SilentlyContinue | Select-Object -Last 1).LastWriteTime
    $updatedmsg = "Lick Hunter Pro has been updated to version $version, please check your settings-$exchange.py"
    
    #Stop bot if running
    if ((Get-Process $websocket -ErrorAction SilentlyContinue) -or (Get-Process $profit -ErrorAction SilentlyContinue)) {
        pm2.cmd delete "$websocketpath\$websocket.exe"
        pm2.cmd delete "$profitpath\$profit.exe"
        pm2.cmd save
        Stop-Process -Name cmd
        Stop-Process -Name node
        }

    #Start bots if version is the latest
    if (Test-Path $versionpath\$version) { 
        
        Write-Host "Version $version is the latest! Starting LickHunterPro!"
        
        if (-not (Test-Path $PSScriptRoot\$settingsbackup)) { 
            New-Item -Path $PSScriptRoot -Name $settingsbackup -ItemType Directory -Force
        }
        
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

    # Update bots if version is not the latest
    Else {

        New-Item -Path $versionpath -Name $version -ItemType Directory
        (New-Object System.Net.WebClient).DownloadFile($realDownloadUrl, $output)
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$versionpath\$version\$fileName","$versionpath\$version")
        Remove-Item -Path $exchange -Recurse -Force
        
        if (-not (Test-Path $PSScriptRoot\$settingsbackup)) { 
            New-Item -Path $PSScriptRoot -Name $settingsbackup -ItemType Directory -Force
        }
        
        if ($original -ne $backup) {
            Copy-Item "$PSScriptRoot\settings-$exchange.py" "$PSScriptRoot\$settingsbackup\$date-settings-$exchange.py" -Recurse
        }
        
        $foldername = (Get-ChildItem -Directory "$versionpath\$version").Name
        Copy-Item "$versionpath\$version\$foldername\$exchange" "$PSScriptRoot" -Recurse
        Copy-Item "$PSScriptRoot\settings-$exchange.py" "$websocketpath\settings.py" -Force
        Copy-Item "$PSScriptRoot\settings-$exchange.py" "$profitpath\settings.py" -Force
        [System.Windows.MessageBox]::Show($updatedmsg)
    }        
}

#Request to install
else {
    $notinstalledmsg = "Lick Hunter Pro is not installed, please run Install-LickHunterPro.ps1"
    [System.Windows.MessageBox]::Show($notinstalledmsg)
}