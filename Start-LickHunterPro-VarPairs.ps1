#API keys (can be read only), paste your API Key and Secret between the quotes, to get your open position and wallet information
$APIKey = "key"
$APISecret = "secret"

#How many pairs do you want to trade?
$maxPairs = "8"

#How many positions do you want to have open?
$maxPositions = "3"

#Open order isolation percentage (Only trades open order pairs when percentage of wallet balance is reached)
$openOrderIsolationPercentage = "10"
#Pairs mode selection
    #Choose 1 for "staticPairs, trade only the pairs you set, not using http://www.lickhunter.com/data/"
    #Choose 2 for "whitelist, trade all pairs that are on your whitelist matched against data from http://www.lickhunter.com/data/"
    #Choose 3 for "tradingAge, trade all pairs on Binance Futures that are available for more than X days matched against data from http://www.lickhunter.com/data/"
    $tradingMode = "3"

        #Trading mode 1: Static pairs, if you only want to use http://www.lickhunter.com/data/
        $staticPairs = 'COMP','BCH','BNB','LINK','TRX','EOS','ADA','ETH','XRP','BAL','LTC','YFI','YFII','ETC','CRV','XTZ','UNI','BAND','DOT','TRB','ATOM','SXP','XLM','SOL','SUSHI','WAVES','ALGO','SNX','NEO','ONT','KAVA','OMG','ZRX','THETA','VET','ZIL','DOGE','IOST','KNC','FLM'

        #Choose the pairs you want to trade from http://www.lickhunter.com/data/
            # Choose 1 for Top 10 burned by Volume - 24h
            # Choose 2 for Top 10 by Liq-Events - 24h
            # Choose 3 for Average Liq-Volume in USD - 24h
            # Choose 4 for Average Liq-Amount - 24h
            $tradePairs = "3"

        #Trading mode 2: Which pairs do you want to whitelist?
        $whitelist = 'COMP','BCH','BNB','LINK','TRX','EOS','ADA','ETH','XRP','BAL','LTC','YFI','YFII','ETC','CRV','XTZ','UNI','BAND','DOT','TRB','ATOM','SXP','XLM','SOL','SUSHI','WAVES','ALGO','SNX','NEO','ONT','KAVA','OMG','ZRX','THETA','VET','ZIL','DOGE','IOST','KNC','FLM'

        #Trading mode 3
        $tradingAge = "45"
        #Which pairs do you want to blacklist?
        $blacklist = 'BTC','DEFI'

#Do you want to use a Funding Rate threshold? Funding Rate explanation https://www.binance.com/en/support/faq/360033525031
#Use $true or $false
$fundingRateThreshold = $true
#maxFundingRate is positive and negative
$maxFundingRate = "0.001"

########################################################################
###DO NOT CHANGE SCRIPT BELOW IF YOU DON'T KNOW WHAT YOU ARE DOING!!!###
########################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Settings file
$settings = ".\settings-Binance.py"
if (Test-Path ".\settings.py") {
    New-Item -ItemType Directory -Name "SettingsBackup" -Force
    Copy-Item -Path ".\settings.py" -Destination ".\SettingsBackup" -Force
    Rename-Item -Path ".\settings.py" -NewName $settings
}

#Stop LickHunterPro if running
Start-Process powershell.exe -ArgumentList ".\Stop-LickHunterPro.ps1" -ErrorAction SilentlyContinue

#Regular expressions
$regexPairs = '(pairs )(.+)'

$currentPairs = ""

Write-Host "Starting LickHunterPro, this can take a minute" -ForegroundColor Cyan
Start-Sleep 15

#while($true) starts a loop for what comes next
while($true) {
    #Date
    $date = Get-Date

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
    $fundingRate = "https://fapi.binance.com/fapi/v1/fundingRate"
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
    $openOrdersMsg = ($openOrders | ForEach-Object {"'$($_)USDT'"}) -join ','
    $openOrdCount = ($accountInformation.positions | Where-Object { $_.initialMargin -ne "0" }).Count

    $lickHunterRunning = Get-Process "Binance*"

    if ($null -eq $lickHunterRunning -or (Get-Date).Minute -eq 0) {
        Start-Sleep -Seconds 30
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
                #Trading mode 3 $tradingAge
                if ($tradingMode -eq "3") {
                    #Remove blacklisted pairs from lickhunter pairs
                    $lickhunterPairs = $lickhunterPairs | Where-Object { $blacklist -notcontains $_ }
                }
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
                #Trading mode 3 $tradingAge
                if ($tradingMode -eq "3") {
                    #Remove blacklisted pairs from lickhunter pairs
                    $lickhunterPairs = $lickhunterPairs | Where-Object { $blacklist -notcontains $_ }
                }
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
                #Trading mode 3 $tradingAge
                if ($tradingMode -eq "3") {
                    #Remove blacklisted pairs from lickhunter pairs
                    $lickhunterPairs = $lickhunterPairs | Where-Object { $blacklist -notcontains $_ }
                }                
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
                #Trading mode 3 $tradingAge
                if ($tradingMode -eq "3") {
                    #Remove blacklisted pairs from lickhunter pairs
                    $lickhunterPairs = $lickhunterPairs | Where-Object { $blacklist -notcontains $_ }
                }                
            }
        }

        if ($fundingRateThreshold -eq $true) {
            $fundingRateData = Invoke-RestMethod -Uri $fundingRate
            $fundingRateData = (($fundingRateData | Where-Object {$_.fundingRate -gt $maxFundingRate} | Sort-Object -Property {[double]$_.fundingRate} -Descending).symbol) | Select-Object -Unique
            $fundingRatePairs = $fundingRateData -replace "USDT", ""
        }

        #Trading mode 1 $staticPairs
        if ($tradingMode -eq "1") {
            $lickhunterPairs = $staticPairs
            #Funding Rate threshold
            if ($fundingRateThreshold -eq $true) {
                $fundingRateMsg = $lickhunterPairs | Where-Object { $fundingRatePairs -eq $_ }
                $fundingRateMsg = ($fundingRateMsg | ForEach-Object {"'$($_)USDT'"}) -join ','
                $lickhunterPairs = $lickhunterPairs | Where-Object { $fundingRatePairs -notcontains $_ }
            }        
        }
        #Trading mode 2 $whitelist
        if ($tradingMode -eq "2") {
            #Match whitelist with lickhunterPairs, removes pairs that do not match
            $lickhunterPairs = (Compare-Object -ReferenceObject $whitelist -DifferenceObject $lickhunterPairs -IncludeEqual -ErrorAction SilentlyContinue | Where-Object { $_.SideIndicator -eq "==" }).InputObject
            #Funding Rate threshold
            if ($fundingRateThreshold -eq $true) {
                $fundingRateMsg = $lickhunterPairs | Where-Object { $fundingRatePairs -eq $_ }
                $fundingRateMsg = ($fundingRateMsg | ForEach-Object {"'$($_)USDT'"}) -join ','
                $lickhunterPairs = $lickhunterPairs | Where-Object { $fundingRatePairs -notcontains $_ }
            }
            $lickhunterPairs = $lickhunterPairs | Select-Object -First $maxPairs
        }
        #Trading mode 3 $tradingAge
        if ($tradingMode -eq "3") {
            $belowTradingAgePairs = @()
            $exchangeInfo = "https://fapi.binance.com/fapi/v1/exchangeInfo"
            $symbols = ((Invoke-RestMethod -Uri $exchangeInfo).symbols).symbol
            foreach ($symbol in $symbols) {
                $klines = "https://fapi.binance.com/fapi/v1/klines?symbol=$symbol&interval=1d"
                $klinesInformation = Invoke-RestMethod -Uri $klines
                if ($klinesInformation.Count -le $tradingAge) {
                    $belowTradingAgePairs += $symbol
                }
            }
            $belowTradingAgePairsMsg = ($belowTradingAgePairs | ForEach-Object {"'$($_)'"}) -join ','
            $belowTradingAgePairs = $belowTradingAgePairs -replace "USDT", ""
            $lickhunterPairs = $lickhunterPairs | Where-Object { $belowTradingAgePairs -notcontains $_ }
            #Funding Rate threshold
            if ($fundingRateThreshold -eq $true) {
                $fundingRateMsg = $lickhunterPairs | Where-Object { $fundingRatePairs -eq $_ }
                $fundingRateMsg = ($fundingRateMsg | ForEach-Object {"'$($_)USDT'"}) -join ','
                $lickhunterPairs = $lickhunterPairs | Where-Object { $fundingRatePairs -notcontains $_ }
            }
            $lickhunterPairs = $lickhunterPairs | Select-Object -First $maxPairs
        }

        $lickhunterPairs | Set-Content ".\lickhunterpairs.txt" -Force
    }

    $lickhunterPairs = Get-Content ".\lickhunterpairs.txt"
    $pairs = $lickhunterPairs | Select-Object -Unique

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
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nSettings changed (re)starting LickHunterPro`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nSettings changed (re)starting LickHunterPro`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
            }
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
            Start-Sleep -Seconds 30
        }        
        else {
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n### Open order isolation is active ###`n" -ForegroundColor Red    
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`n### Open order isolation is active ###`n" -ForegroundColor Red
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`n### Open order isolation is active ###`n" -ForegroundColor Red    
                }
            }
        }
    }
    elseif ($openOrdCount -ge $maxPositions) {        
        if ($tradingPairs -ne $currentPairs) {
            (Get-Content -Path $settings) | Foreach-Object {
                $_ -replace $regexPairs, "pairs = [$tradingPairs]"
                } | Set-Content $settings
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n### Trading maximum orders ###`n" -ForegroundColor Yellow
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n### Trading maximum orders ###`n" -ForegroundColor Yellow    
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nSettings changed (re)starting LickHunterPro`n### Trading maximum orders ###`n" -ForegroundColor Yellow
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nSettings changed (re)starting LickHunterPro`n### Trading maximum orders ###`n" -ForegroundColor Yellow    
                }
            }
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
            Start-Sleep -Seconds 30
        }
        
        else {
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n### Trading maximum open orders ###`n" -ForegroundColor Yellow
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n### Trading maximum open orders ###`n" -ForegroundColor Yellow
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`n### Trading maximum open orders ###`n" -ForegroundColor Yellow
                }
                else {
                    Write-Host "$date`nOpen Orders: $openOrdersMsg`n### Trading maximum open orders ###`n" -ForegroundColor Yellow
                }
            }
        
        }
    }
    else {        
        if ($tradingPairs -ne $currentPairs) {
            (Get-Content -Path $settings) | Foreach-Object {
                $_ -replace $regexPairs, "pairs = [$tradingPairs]"
                } | Set-Content $settings
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nPairs adjusted to: $tradingPairs`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n" -ForegroundColor Green
                }
                else {
                    Write-Host "$date`nPairs adjusted to: $tradingPairs`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`nSettings changed (re)starting LickHunterPro`n" -ForegroundColor Green
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nPairs adjusted to: $tradingPairs`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nSettings changed (re)starting LickHunterPro`n" -ForegroundColor Green
                }
                else {
                    Write-Host "$date`nPairs adjusted to: $tradingPairs`nOpen Orders: $openOrdersMsg`nSettings changed (re)starting LickHunterPro`n" -ForegroundColor Green
                }
            }
            Start-Process powershell.exe -ArgumentList ".\LickHunterPro.ps1"
            Start-Sleep -Seconds 30
        }        
        else {
            if ($tradingMode -eq "3") {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nCurrently trading: $currentPairs`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n" -ForegroundColor Green
                }
                else {
                    Write-Host "$date`nCurrently trading: $currentPairs`nOpen Orders: $openOrdersMsg`nPairs below tradingAge: $belowTradingAgePairsMsg`n" -ForegroundColor Green
                }
            }
            else {
                if ($fundingRateThreshold -eq $true) {
                    Write-Host "$date`nCurrently trading: $currentPairs`nOpen Orders: $openOrdersMsg`nPairs above Funding Rate threshold: $fundingRateMsg`n" -ForegroundColor Green
                }
                else {
                    Write-Host "$date`nCurrently trading: $currentPairs`nOpen Orders: $openOrdersMsg`n" -ForegroundColor Green
                }
            }
        }
    }

    $currentPairs = $tradingPairs

    Start-Sleep -Seconds 2
}