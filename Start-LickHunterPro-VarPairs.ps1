#API keys (can be read only), paste your API Key and Secret between the quotes, to get your open position and wallet information
$APIKey = "key"
$APISecret = "secret"

#Choose the pairs you want to trade from http://www.lickhunter.com/data/
    # Choose 1 for Top 10 burned by Volume - 24h
    # Choose 2 for Top 10 by Liq-Events - 24h
    # Choose 3 for Average Liq-Volume in USD - 24h
    # Choose 4 for Average Liq-Amount - 24h
$tradePairs = "1"

#How many pairs do you want to trade?
$maxPairs = "8"

#How many positions do you want to have open?
$maxPositions = "3"

#Open order isolation percentage (Only trades open order pairs when percentage of wallet balance is reached)
$openOrderIsolationPercentage = "10"

#Do you want to trade newly added pairs on Binance Futures? $true or $false
$newPairs = $false

#Which pairs do you want to blacklist?
$blacklist = 'BTC','DEFI'

########################################################################
###DO NOT CHANGE SCRIPT BELOW IF YOU DON'T KNOW WHAT YOU ARE DOING!!!###
########################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Settings file
$settings = ".\settings-Binance.py"
if (Test-Path ".\settings.py") {
    Rename-Item -Path ".\settings.py" -NewName $settings
}

#Regular expressions
$regexPairs = '(pairs )(.+)'

$currentPairs = ""

#while($true) starts a loop for what comes next
while($true) {
    #Date
    $date = Get-Date

    #Get liquidation information
    $url = "http://liquidationsniper.com/charts.php"
    $content = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction SilentlyContinue
    #Get pairs from Top 10 burned by Volume - 24h
    if ($tradePairs -eq "1") {
        if ($content.rawContent -like '*under*construction!*') {
            $lastusedpairs = Get-Content ".\lastusedpairs.txt"
            $lickhunterPairs = $lastusedpairs
        }
        else {
            $content.rawContent -match '(?sm)var.chart.*?render.*?$' | Out-Null
            $varchart2 = $Matches.0
            $varchart2 -match '(dataPoints:.*])' | Out-Null
            $datapoints = $Matches.1
            $top10burned = Select-String '{.label.*?}' -InputObject $datapoints -AllMatches | ForEach-Object {$_.Matches}
            $top10burnedpairs = $top10burned.Value
            $top10s=@()
            $top10burnedpairs | ForEach-Object{
                $top10s+=New-Object PSObject -Property @{    
                'String'=([regex]::Match($_,'(\b\w[A-Z]{2}\b|\b\w[A-Z]{3}\b|\b\w[A-Z]{4}\b)')).Value
                'Numeric'=[int]([regex]::Match($_,'\d+')).Value
                }
            }
        $lickhunterPairs = ($top10s | Sort-Object -Property Numeric -Descending).String
        $lickhunterPairs | Set-Content ".\lastusedpairs.txt" -Force
        }
    }

    #Get pairs from Top 10 by Liq-Events - 24h
    if ($tradePairs -eq "2") {
        if ($content.rawContent -like '*under*construction!*') {
            $lastusedpairs = Get-Content ".\lastusedpairs.txt"
            $lickhunterPairs = $lastusedpairs
        }
        else {
            $content.rawContent -match '(?sm)var.chart2.*?render.*?$' | Out-Null
            $varchart2 = $Matches.0
            $varchart2 -match '(dataPoints:.*])' | Out-Null
            $datapoints = $Matches.1
            $Top10Liq = Select-String '{.label.*?}' -InputObject $datapoints -AllMatches | ForEach-Object {$_.Matches}
            $Top10Liqs = $Top10Liq.Value
            $t10Liqs=@()
            $Top10Liqs | ForEach-Object{
                $t10Liqs+=New-Object PSObject -Property @{                    
                'String'=([regex]::Match($_,'(\b\w[A-Z]{2}\b|\b\w[A-Z]{3}\b|\b\w[A-Z]{4}\b)')).Value
                'Numeric'=[int]([regex]::Match($_,'\d+')).Value
                }
            }
            $lickhunterPairs = ($t10Liqs | Sort-Object -Property Numeric -Descending).String
            $lickhunterPairs | Set-Content ".\lastusedpairs.txt" -Force
        }
    }

    #Get pairs from Average Liq-Volume in USD - 24h
    if ($tradePairs -eq "3") {
        if ($content.rawContent -like '*under*construction!*') {
            $lastusedpairs = Get-Content ".\lastusedpairs.txt"
            $lickhunterPairs = $lastusedpairs
        }
        else {
            $content.rawContent -match '(?sm)var.chartAVGVolume.*?render.*?$' | Out-Null
            $varchart2 = $Matches.0
            $varchart2 -match '(dataPoints:.*])' | Out-Null
            $datapoints = $Matches.1
            $averageLiq = Select-String '{.label.*?}' -InputObject $datapoints -AllMatches | ForEach-Object {$_.Matches}
            $averageLiqs = $averageLiq.Value
            $avgLiqs=@()
            $averageLiqs | ForEach-Object{
                $avgLiqs+=New-Object PSObject -Property @{                    
                'String'=([regex]::Match($_,'(\b\w[A-Z]{2}\b|\b\w[A-Z]{3}\b|\b\w[A-Z]{4}\b)')).Value
                'Numeric'=[int]([regex]::Match($_,'\d+')).Value
                }
            }
            $lickhunterPairs = ($avgLiqs | Sort-Object -Property Numeric -Descending).String
            $lickhunterPairs | Set-Content ".\lastusedpairs.txt" -Force
        }
    }    

    #Get pairs from Average Liq-Amount - 24h
    if ($tradePairs -eq "4") {
        if ($content.rawContent -like '*under*construction!*') {
            $lastusedpairs = Get-Content ".\lastusedpairs.txt"
            $lickhunterPairs = $lastusedpairs
        }
        else {
            $content.rawContent -match '(?sm)var.chartAVGLiq.*?render.*?$' | Out-Null
            $varchart2 = $Matches.0
            $varchart2 -match '(dataPoints:.*])' | Out-Null
            $datapoints = $Matches.1
            $averageLiqA = Select-String '{.label.*?}' -InputObject $datapoints -AllMatches | ForEach-Object {$_.Matches}
            $averageLiqAs = $averageLiqA.Value
            $avgLiqAs=@()
            $averageLiqAs | ForEach-Object{
                $avgLiqAs+=New-Object PSObject -Property @{                    
                'String'=([regex]::Match($_,'(\b\w[A-Z]{2}\b|\b\w[A-Z]{3}\b|\b\w[A-Z]{4}\b)')).Value
                'Numeric'=[int]([regex]::Match($_,'\d+')).Value
                }
            }
            $lickhunterPairs = ($avgLiqAs | Sort-Object -Property Numeric -Descending).String
            $lickhunterPairs | Set-Content ".\lastusedpairs.txt" -Force
        }
    }

    #Query Coingecko for Binance Futures if not in this list pairs are newly trading
    $coingeckoFutures = Invoke-RestMethod -Uri "https://api.coingecko.com/api/v3/derivatives/exchanges/binance_futures?include_tickers=all"
    $coingeckoFutures = ($coingeckoFutures.tickers).base | Select-Object -Unique
    $notradePairs = (Compare-Object -ReferenceObject $coingeckoFutures -DifferenceObject $lickhunterPairs -ErrorAction SilentlyContinue | Where-Object { $_.SideIndicator -eq "=>" }).InputObject

    #If $newPairs is $false, remove $newPairs from $assets
    if ($newPairs -eq $false ) {
        $lickhunterPairs = $lickhunterPairs | Where-Object { $notradePairs -notcontains $_ }
    }

    #Remove blacklisted pairs from lickhunter pairs
    $lickhunterPairs = $lickhunterPairs | Where-Object { $blacklist -notcontains $_ }

    #Get current open orders, total wallet balance and total intial margin on Binance
    $unixEpochStart = Get-Date -Date "01/01/1970"
    $now = Get-Date
    $TimeStamp = (New-TimeSpan -Start $unixEpochStart -End $now.ToUniversalTime()).TotalMilliseconds
    $TimeStamp = ([math]::Round($timestamp, 0)).ToString()
    $QueryString = "&recvWindow=5000&timestamp=$TimeStamp"
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($APISecret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($QueryString))
    $signature = [System.BitConverter]::ToString($signature).Replace('-', '').ToLower()
    $uriopenorders = "https://fapi.binance.com/fapi/v1/account?$QueryString&signature=$signature"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-MBX-APIKEY",$APIKey)
    $accountInformation = Invoke-RestMethod -Uri $uriopenorders -Headers $headers -Method Get
    $totalWalletBalance = $accountInformation.totalWalletBalance
    $totalInitialMargin = $accountInformation.totalInitialMargin
    $marginWalletPercentage = ($totalInitialMargin/$totalWalletBalance) * 100
    $openOrders = @()
    $Orders = ($accountInformation.positions | Where-Object { $_.initialMargin -ne "0" }).symbol
    foreach ($Order in $Orders) {
        $Order = $Order -replace "(USDT)", ""
        $openOrders += $Order
    }
    $openOrdCount = ($accountInformation.positions | Where-Object { $_.initialMargin -ne "0" }).Count

    #openOrders + maxPairs
    $lickhunterPairs = $lickhunterPairs | Select-Object -First $maxPairs
    $pairs = $openOrders + $lickhunterPairs | Select-Object -Unique

    #Open order isolation
    if ($marginWalletPercentage -gt $openOrderIsolationPercentage) {
        $tradingPairs = @()
        foreach ($openOrder in $openOrders) {
            $openOrder = "'$($openOrder)USDT'"
            $tradingPairs += $openOrder
        }
    }
    #Maximum orders
    elseif ($openOrdCount -ge $maxPositions) {
        $tradingPairs = @()
        foreach ($openOrder in $openOrders) {
            $openOrder = "'$($openOrder)USDT'"
            $tradingPairs += $openOrder
        }
    }
    else {
        $tradingPairs = @()
        foreach ($pair in $pairs) {
            $pair = "'$($pair)USDT'"
            $tradingPairs += $pair
        }
    }

    #Used for pairs = [...] in settings.py
    $tradingPairs = ($tradingPairs | Select-Object -Unique) -join ','

    #Update tradingpairs if changed
    if ($marginWalletPercentage -gt $openOrderIsolationPercentage) {        
        if ($tradingPairs -ne $currentPairs) {
            (Get-Content -Path $settings) | Foreach-Object {
                $_ -replace $regexPairs, "pairs = [$tradingPairs]"
                } | Set-Content $settings
            Write-Host "$date`nPairs adjusted to: $tradingPairs`nSettings changed (re)starting LickHunterPro`n### Open order isolation is active ###`n" -ForegroundColor Red
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
        }        
        else {
            Write-Host "$date`nCurrently trading: $currentPairs`n### Open order isolation is active ###`n" -ForegroundColor Red
        }
    }
    elseif ($openOrdCount -ge $maxPositions) {        
        if ($tradingPairs -ne $currentPairs) {
            (Get-Content -Path $settings) | Foreach-Object {
                $_ -replace $regexPairs, "pairs = [$tradingPairs]"
                } | Set-Content $settings
            Write-Host "$date`nPairs adjusted to: $tradingPairs`nSettings changed (re)starting LickHunterPro`n### Trading maximum orders ###`n" -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
        }
        
        else {
            Write-Host "$date`nCurrently trading: $currentPairs`n### Trading maximum open orders ###`n" -ForegroundColor Yellow
        }
    }
    else {        
        if ($tradingPairs -ne $currentPairs) {
            (Get-Content -Path $settings) | Foreach-Object {
                $_ -replace $regexPairs, "pairs = [$tradingPairs]"
                } | Set-Content $settings
            Write-Host "$date`nPairs adjusted to: $tradingPairs`nSettings changed (re)starting LickHunterPro`n" -ForegroundColor Green
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
        }        
        else {
            Write-Host "$date`nCurrently trading: $currentPairs`n" -ForegroundColor Green
        }
    }

    $currentPairs = $tradingPairs

    Start-Sleep -Seconds 30
}