<#

Script written for personal use by Mutu Adi-Marian (aka xs8 or Xxshark888xX) free for use without any license


The main usecase for this script is when you swapped a coin (example: DGB - DigiByte to LTC - Litecoin) and you want to know how much you'll get if swaps back

#>

#Add-Type -AssemblyName System.Windows.Forms;


write-host -ForegroundColor Yellow -BackgroundColor Black "Developed by Mutu Adi-Marian & Powered by CryptoCompare.com | v1.0.1`n`n`n";
[console]::WindowWidth=100; [console]::WindowHeight=35;

# Default value for the "main" file
$fileDefaultValue = "# Isn't mandatory to have an API Key to use CryptoCompare's API
# Anyway, you can get a free one by accessing this link https://www.cryptocompare.com/cryptopian/api-keys
apiKey=

# Select an exchange from where to get the data for the profit calculation
# You can see a list of all the exchanges available and their coin pair by accessing this link https://min-api.cryptocompare.com/data/v2/all/exchanges (By default is CCCAGG)
exchange=CCCAGG

# Coin ticker (this will show the profit gain (%) based on the selected coin)
coin=DGB

# Returns the value of the total amount of coins you hold (after the profit calculation) in the selected fiat
fiat=GBP

# In order to calculate the swap profit, you need to add every swap you did by writing them on a new line (minimum 1 swap required)
#
# Template of the swap info
# [X/Y]Z/S
# X = From which coin you swapped (Example: DGB)
# Y = Coin swapped to (Example: LTC)
# Z = Amount of coin swapped (Example 25000 DGB)
# S = Amount of coin recevied back after the swap (Example: 4.9811 LTC)

[DGB/LTC]25000>4.9811";


$filePath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\";

if (!(Test-Path -Path "$($filePath)main.txt")) {
    #creating new file

    Set-Content -Path "$($filePath)main.txt" -Value $fileDefaultValue;

    Read-Host "'main.txt' file not found, creating a new one...`nEdit the file and re-open the script`n`nPress enter to exit";
} else {
    $apiKey;
    $exchange;
    $baseCoin;
    $fiatSymbol;
    $baseCoinFiatValue      = 0;
    $pairCoin               = New-Object Collections.Generic.List[string[]];
    $baseCoinNewAmount      = 0;
    $baseCoinOriginalAmount = 0;
    $profitChange           = New-Object Collections.Generic.List[string];
    $profitChangeActive     = $false;


    #reads the 'trace' file to calculate the profit changes from the las time
    if ((Test-Path -Path "$($filePath)profit.tr")) {
        $profitChangeActive = $true;

        $fileArray = Get-Content -Path "$($filePath)profit.tr";
        foreach ($_s In $fileArray) {
            $profitChange.Add($_s);
        }

        #calculates the time passed from the last profit verification
        $profitChange[0] = [string](new-timespan –start $([datetime]$profitChange[0]) –end $([datetime]$(Get-Date -format G)));
        $profitChange[0] = $("{0} day(s) {1}h:{2}m:{3}s" -f $([timespan]$profitChange[0]).Days, $([timespan]$profitChange[0]).Hours, $([timespan]$profitChange[0]).Minutes, $([timespan]$profitChange[0]).Seconds);
    }
    
    #reads the 'main.txt' file
    [string[]]$fileArray = Get-Content -Path "$($filePath)main.txt";
    foreach ($_s In $fileArray) {
        #lines which starts with '#' are comments

        if (!($_s.StartsWith('#') -or [string]::IsNullOrEmpty($_s))) {
            if ($_s.StartsWith("apiKey")) {
                $apiKey = $_s.Substring($_s.IndexOf('=') + 1);
            } elseif ($_s.StartsWith("exchange")) {
                $exchange = $_s.Substring($_s.IndexOf('=') + 1);
            }
             elseif ($_s.StartsWith("coin")) {
                #retrieves the base coin ticker
                $baseCoin = $_s.Substring($_s.IndexOf('=') + 1);
            } elseif ($_s.StartsWith("fiat")) {
                #retrieves the fiat currency
                if ($_s.Substring($_s.IndexOf('=') + 1).Length -gt 0) {
                    $fiatSymbol = $_s.Substring($_s.IndexOf('=') + 1);
                } else { $fiatSymbol = "GBP"; }
            } else {
                #retrieves the investment coin
                $_coinFrom       = $_s.Substring(1, $_s.IndexOf('/') - 1);
                #retrieves the recevied coin
                $_coinTo         = $_s.Substring($_s.IndexOf('/') + 1, ($_s.IndexOf(']') - $_s.IndexOf('/')) - 1);
                #retrieves the amount of the investment coin
                $_coinInvestment = $_s.Substring($_s.IndexOf(']') + 1, ($_s.IndexOf('>') - $_s.IndexOf(']')) - 1);
                #retrieves the amount recevied from the swap
                $_coinAmountSwap = $_s.Substring($_s.IndexOf('>') + 1);

                $pairCoin.Add(@($_coinFrom, $_coinTo, $_coinInvestment, $_coinAmountSwap, 0, 0, 0));
                #the 4th index is the current value of the swapped coin in 'baseCoin'
                #the 5th index is the current value of the swapped coin in fiat
                #the 6th index is the profit change
            }
        }
    }

    #parses the 'pairCoin' array to create a valid parameter for the CryptoCompare API
    $uniqueStringAllCoins;
    for ($i = 1; $i -le $pairCoin.Count; $i++) {
        $uniqueStringAllCoins += $pairCoin[$i - 1][1];

        if ($i -lt $pairCoin.Count -and $i -ne $pairCoin.Count) {
            $uniqueStringAllCoins += ',';
        }
    }


    try {
        #performs the GET call to CryptoCompare
        #parses the JSON response
        ((New-Object System.Net.WebClient).downloadString("https://min-api.cryptocompare.com/data/pricemulti?fsyms=$baseCoin,$uniqueStringAllCoins&tsyms=$baseCoin,$fiatSymbol&e=$exchange&api_key=$apiKey") | ConvertFrom-Json) | ForEach-Object {
            #if the response contains an error message will print it
            if ($_.psobject.properties.value[0] -eq "Error") {
                read-host "EXCHANGE ERROR: `n`n$($_.psobject.properties.value[1])`n`nPress 'ENTER' to exit";

                Stop-Process -Id $PID;
            }

            for ($i = 0; $i -lt $pairCoin.Count + 1; $i++) {
                #retrieves the current fiat value for the 'baseCoin'
                if ($_.psobject.properties.name[$i] -eq $baseCoin) {
                    foreach ($_value in $_.psobject.properties.value[0]) {
                        $baseCoinFiatValue = $_value.psobject.properties.value[1];
                    }
                }

                #retrieves the current fiat and 'baseCoin' value for the swapped coin
                elseif ($_.psobject.properties.name[$i] -eq $pairCoin[$i - 1][1]) {
                    foreach ($_value in $_.psobject.properties.value[$i]) {
                        #baseCoin
                        $pairCoin[$i - 1][4] = $_value.psobject.properties.value[0];
                        #fiat
                        $pairCoin[$i - 1][5] = $_value.psobject.properties.value[1];

                        #retrieves the new amount of the 'baseCoin'
                        $baseCoinNewAmount      += [decimal]$pairCoin[$i - 1][3] * [decimal]$pairCoin[$i - 1][4];
                        #retrieves also the original amount of the base coin
                        $baseCoinOriginalAmount += [decimal]$pairCoin[$i - 1][2];
                    }
                }
            }
        }

        #draws the 'Overall Profit' informations
        #converts the total profit in fiat for the 'baseCoin'
        $fiatValueTotal         = [decimal][math]::Round([decimal]($baseCoinNewAmount * $baseCoinFiatValue), 2);
        #calculates the total % profit for the 'baseCoin'
        $baseCoinProfit         = [decimal][math]::Round((($baseCoinNewAmount - $baseCoinOriginalAmount) / $baseCoinOriginalAmount) * 100, 2);
        #calculates the profit change from the last time for the 'baseCoin' fiat value
        if ($profitChangeActive -eq $true) {
            #avoids dividing by 0
            if ($baseCoinProfit -ne 0 -and [decimal]$profitChange[1] -ne 0) {
                $_fiatValueProfitChange = [decimal][math]::Round((([decimal]$profitChange[1] - $fiatValueTotal) / [decimal]$profitChange[1]) * 100, 2);
            } else { $_fiatValueProfitChange = 100; }

            write-host -ForegroundColor Yellow "{Overall informations | Profit Difference Since (PDS) => $($profitChange[0])}"
        } else {
            write-host -ForegroundColor Yellow "{Overall informations}"
        }

        
        write-host -NoNewline "[1 $($baseCoin)]:        $baseCoinFiatValue $fiatSymbol`nOriginal value: $baseCoinOriginalAmount $baseCoin`nCurrent value:  $baseCoinNewAmount $baseCoin => $fiatValueTotal $fiatSymbol ";
        if ($fiatValueTotal -ge [decimal]$profitChange[1]) {
            if ($profitChangeActive -eq $true) {
                write-host -NoNewline -ForegroundColor Green -BackgroundColor Black "PDS: $([math]::abs($_fiatValueProfitChange))%↑";
            }
        } else {
            if ($profitChangeActive -eq $true) {
                write-host -NoNewline -ForegroundColor Red -BackgroundColor Black "PDS: $([math]::abs($_fiatValueProfitChange))%↓";
            }
        }
        write-host -NoNewline "`n";

        #if the current total profit is greater than 0 will print the % in green otherwise in red
        if ($baseCoinProfit -ge 0) {
            write-host -NoNewline -ForegroundColor Green -BackgroundColor Black "Total Profit:   $([math]::abs($baseCoinProfit))%↑";
        } else {
            write-host -NoNewline -ForegroundColor Red   -BackgroundColor Black "Total Profit:   $([math]::abs($baseCoinProfit))%↓";
        }

        if ($profitChangeActive -eq $true) {
            #calculates the profit change from the last time for the 'baseCoin' (TOTAL PROFIT)
            #avoids dividing by 0
            if ([decimal]$profitChange[2] -ne 0) {
                $_profitChange = [decimal][math]::Round((($baseCoinProfit - [decimal]$profitChange[2]) / [decimal]$profitChange[2]) * 100, 2);
            } else { $_profitChange = $baseCoinProfit; }

            #if the profit change is greater than 0 will print the % in green otherwise in red
            if ($baseCoinProfit -ge [decimal]$profitChange[2]) {
                write-host -ForegroundColor Green -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↑)`n`n`n`n";
            } else {
                write-host -ForegroundColor Red   -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↓)`n`n`n`n";
            }
        } else { write-host "`n`n`n`n"; } 


        #calculates the individual % profit
        write-host -ForegroundColor Yellow "{Individual profit}`n"
        for ($i = 0; $i -lt $pairCoin.Count; $i++) {
            $_indBaseCoinCurrentAmount = [decimal]$pairCoin[$i][3] * [decimal]$pairCoin[$i][4];
            $_indProfit                = [decimal][math]::Round((($_indBaseCoinCurrentAmount - $pairCoin[$i][2]) / $pairCoin[$i][2]) * 100, 2);

            write-host -ForegroundColor Cyan -BackgroundColor Black "===[1"($pairCoin[$i][1])"="([decimal]$pairCoin[$i][4])"$baseCoin =>"($pairCoin[$i][5])"$fiatSymbol]===";
            write-host "Original amount: $($pairCoin[$i][2])$($pairCoin[$i][0])`nCurrent amount:  $_indBaseCoinCurrentAmount $baseCoin";
            #if the individual profit is greater than 0 will print the % in green otherwise in red
            if ($_indProfit -ge 0) {
                write-host -NoNewline -ForegroundColor Green -BackgroundColor Black ("Profit:          $([math]::abs($_indProfit))%↑");
            } else {
                write-host -NoNewline -ForegroundColor Red   -BackgroundColor Black ("Profit:          $([math]::abs($_indProfit))%↓");
            }

            if ($profitChangeActive -eq $true) {
                #calculates the profit change from the last time for the swapped coin (INDIVIDUAL PROFIT)
                #avoids dividing by 0
                if ([decimal]$profitChange[$i + 3] -ne 0) {
                    $_profitChange = [decimal][math]::Round((($_indProfit - [decimal]$profitChange[$i + 3]) / [decimal]$profitChange[$i + 3]) * 100, 2);
                } else { $_profitChange = $_indProfit; }

                #if the profit change is greater than 0 will print the % in green otherwise in red
                if ($_indProfit -ge 0) {
                    write-host -ForegroundColor Green -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↑)`n";
                } else {
                    write-host -ForegroundColor Red   -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↓)`n";
                }
            } else { write-host "`n"; } 
        }

        #updates the trace file with the current % profit to make a comparasion the next time
        $_traceFileValue  = "$(Get-Date -Format G)`n"; #timestamp from last verification
        $_traceFileValue += "$fiatValueTotal`n";
        $_traceFileValue += "$baseCoinProfit`n";
        for ($i = 0; $i -lt $pairCoin.Count; $i++) {
            $_traceFileValue += "$([math]::Round(((([decimal]$pairCoin[$i][3] * [decimal]$pairCoin[$i][4]) - $pairCoin[$i][2]) / $pairCoin[$i][2]) * 100, 2))`n";
        }
        Set-Content -Path "$($filePath)profit.tr" -Value $_traceFileValue;

        # If the 'R' is pressed the script will restart
        write-host -NoNewline -ForegroundColor Yellow "`n`n`nPress 'R' to refresh or just press 'E' to exit";
        while($true) {
            if ($Host.UI.RawUI.ReadKey().Character -eq 'E') { break; } 

            #if ([Windows.Forms.UserControl]::MouseButtons -match "Right") {
            elseif ($Host.UI.RawUI.ReadKey().Character -eq 'R') {
                Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoExit', '-File', """$PSCommandPath""";

                break;
            }

            # Used to avoid too much CPU consuming
            Start-Sleep -Milliseconds 1;
        }
    } catch {
        Clear-Host;
        write-host -ForegroundColor Red -BackgroundColor Black "Something bad happened...`n`n`nError: $($_.Exception)`n$($_.ScriptStackTrace)`n`n";
        write-host -ForegroundColor Yellow -BackgroundColor Black "Please send an e-mail to 'mutu.adi.marian@gmail.com' with the highlighted error above`n`nPress enter to exit...";
        read-host;
    }
}

Stop-Process -Id $PID;
