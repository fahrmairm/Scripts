$versionpath = "$PSScriptRoot\Versions"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://github.com/CryptoGnome/LickHunterPRO/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')
$fileName = "Lick.Hunter.Pro.v$version.zip"
$realDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/' + $fileName
$output = "$versionpath\$version\$fileName"
$prereq = "Prerequisites"
$nodejs = "C:\Program Files\nodejs"

Add-Type -AssemblyName PresentationFramework
Add-Type -Assembly "System.IO.Compression.Filesystem"

if (-not (Test-Path "C:\Program Files\nodejs")) {
    $urlnodejs = "https://nodejs.org/dist/v12.8.0/node-v12.8.0-x64.msi"
    if (-not (Test-Path $PSScriptRoot/$prereq)) {
        New-Item -Path . -Name $prereq -ItemType Directory -Force
        }
    $output = "$PSScriptRoot\$prereq\node-v12.8.0-x64.msi"
    (New-Object System.Net.WebClient).DownloadFile($urlnodejs, $output)
    Start-Process msiexec.exe -Wait -ArgumentList "/i $output /qn"
    Start-Process $nodejs\npm.cmd -Wait -ArgumentList "install -g npm"
    Start-Process $nodejs\npm.cmd -Wait -ArgumentList "install pm2@latest -g"
    }

function Show-Menu
{
     param (
           [string]$Title = 'What exchange do you want to use?'
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: Press '1' for Binance."
     Write-Host "2: Press '2' for Bybit."
     Write-Host "Q: Press 'Q' to quit."
}

do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           '1' {
                $exchange = "Binance"
                'You chose option #1 Binance'
           } '2' {
                $exchange = "Bybit"
                'You chose option #2 Bybit'
           } 'q' {
                return
           }
     }
#     pause
}
until ($input -eq 'q' -or $input -eq '1' -or $input -eq '2')

$allreadyinstalledmsg = "Lick Hunter Pro is allready installed, you cannot install two bots in the same folder!"
$successfullyinstalledmsg = "Lick Hunter Pro for $exchange is successfully installed!"
$downloadfailedmsg

If ((Test-Path $PSScriptRoot\Binance) -eq $true -or (Test-Path $PSScriptRoot\Bybit) -eq $true) {
    [System.Windows.MessageBox]::Show($allreadyinstalledmsg)
}
    
Else {
    New-Item -Path $versionpath -Name $version -ItemType Directory -ErrorAction SilentlyContinue
    (New-Object System.Net.WebClient).DownloadFile($realDownloadUrl, $output)
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$versionpath\$version\$fileName","$versionpath\$version")
    Remove-Item -Path "$PSScriptRoot\$exchange" -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $versionpath\$version\$fileName)) {
        [System.Windows.MessageBox]::Show($downloadfailedmsg)
        }
    else {
        $foldername = (Get-ChildItem -Directory "$versionpath\$version").Name
        Copy-Item "$versionpath\$version\$foldername\$exchange" "$PSScriptRoot" -Recurse
        Copy-Item "$versionpath\$version\$foldername\settings.py" "$PSScriptRoot\settings-$exchange.py"
        [System.Windows.MessageBox]::Show($successfullyinstalledmsg)
        }
}