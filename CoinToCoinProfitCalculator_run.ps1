<#

Script written for personal use by Mutu Adi-Marian (aka xs8 or Xxshark888xX) free for use without any license


The main usecase for this script is when you swapped a coin (example: DGB - DigiByte to LTC - Litecoin) and you want to know how much you'll get if swaps back

#>

#Add-Type -AssemblyName System.Windows.Forms;


clear-host;
write-host -ForegroundColor Yellow -BackgroundColor Black "Developed by Mutu Adi-Marian & Powered by CryptoCompare.com | v2.1.2`n`n";
[console]::WindowWidth=111; [console]::WindowHeight=37;

# FUNCTIONS #

# Returns into an array the informations about the coin pair using CryptoCompare's API
function GetCoinPairInfo {
    #fromTicker = Coin symbol swapped from
    #toTicker   = Coin symbol swapped to
    #fiatTicker = Fiat symbol to convert the coins
    #ex         = Exchange
    #apiKey     = CryptoCompare's API key (not mandatory)
    param([string]$fromTicker, [string]$toTicker, [string]$fiatTicker, [string]$ex = "CCCAGG", [string]$apiKey);

    #the array which will contain the response from CryptoCompare's API
    $dataReturn = @(0, 0);
      
    #performs the GET call
    ((New-Object System.Net.WebClient).downloadString("https://min-api.cryptocompare.com/data/pricemulti?fsyms=$fromTicker&tsyms=$toTicker,$fiatTicker&e=$ex&api_key=$apiKey") | ConvertFrom-Json) | ForEach-Object {
        if ($_.psobject.properties.value[0] -eq "Error" -and !($_.psobject.properties.value[1] -eq "$ex market does not exist for this coin pair ($toTicker-$fromTicker)")) {
            clear-host;

            write-host -ForegroundColor Yellow -BackgroundColor Black "Exchange error: `n`n";
            write-host -ForegroundColor Red -BackgroundColor Black "$($_.psobject.properties.value[1])`n`n";

            RefreshExitLoop;
        }


        foreach ($_value in $_.psobject.properties.value[0]) {
            $dataReturn[0] = $_value.psobject.properties.value[0];
            $dataReturn[1] = $_value.psobject.properties.value[1];
        }
    }

    #returns an array which will contain into the first index the value of 1 'fromTicker' in 'toTicker' and into the 2nd index will contain the value of 1 'fromTicker' in 'fiatTicker'
    return $dataReturn;
}

# Calculates the % value betweens the given numbers
function CalculatePercent {
    #oAmount = Original Amount
    #nAmount = New Amount
    #dRound  = Decimal Round
    
    # Returns the % difference between the 'Original Amount' and the 'New Amount'

    param([decimal]$oAmount, [decimal]$nAmount, [int]$dRound);

    if ($nAmount -eq 0 -or $oAmount -eq 0) {
        return [decimal]0;
    } else {
        return [decimal][math]::Round((($nAmount - $oAmount) / $oAmount) * 100, $dRound);
    }
}

# Used for the 'Refresh or exit' question
function RefreshExitLoop {
    param([int]$autoRefreshSeconds = 0);

    #if the 'R' is pressed the script will restart
    write-host -NoNewline -ForegroundColor Yellow "`n`nPress 'R' to refresh or any key to exit`n`n";

    #autorefresh function
    $_stopWatch;
    if ($autoRefreshSeconds -gt 0) {
        $_stopWatch = [System.Diagnostics.Stopwatch]::StartNew();
        $_stopWatch.Start();
    }

    while ($true) {
        if ($Host.UI.RawUI.KeyAvailable) {
            if ($Host.UI.RawUI.ReadKey().Character -eq 'R') {
                Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoExit', '-File', """$PSCommandPath""";

                break;
            } else { break; }
        }

        if ($autoRefreshSeconds -gt 0) {
            write-host -NoNewline -ForegroundColor Yellow ("`r > Autorefresh in $([math]::Round($autoRefreshSeconds - $_stopWatch.Elapsed.TotalSeconds)) seconds...").PadRight([console]::WindowWidth, ' ');

            if ($_stopWatch.Elapsed.TotalSeconds -ge $autoRefreshSeconds) {
                Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoExit', '-File', """$PSCommandPath""";

                break;
            }
        }

        start-sleep -Milliseconds 1;
    }

    Stop-Process -Id $PID;
}

# Default value for the "main" file
$fileDefaultValue = "# Isn't mandatory to have an API Key to use CryptoCompare's API
# Anyway, you can get a free one by accessing this link https://www.cryptocompare.com/cryptopian/api-keys
apiKey=

# Hides the overall profit informations section (true or false)
hideOverallSection=false

# Autorefresh rate in seconds (leave 0 to disable)
autorefreshRate=10

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
# [X/Y]Z>S
# X = From which coin you swapped (Example: DGB)
# Y = Coin swapped to (Example: LTC)
# Z = Amount of coin swapped (Example 25000 DGB)
# S = Amount of coin recevied back after the swap (Example: 4.9811 LTC)

[DGB/LTC]25000>4.9811";


$filePath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\";

if (!(Test-Path -Path "$($filePath)main.txt")) {
    #creating new file

    Set-Content -Path "$($filePath)main.txt" -Value $fileDefaultValue;

    write-host -ForegroundColor Red -BackgroundColor Black "'main.txt' file not found, creating a new one...`nEdit the file and re-open the script`n";

    RefreshExitLoop;
} else {
    try {
        $apiKey;
        $hideOverallSection     = 0;
        $autoRefreshSec         = 10;
        $exchange;
        $baseCoin;
        $fiatValueTotal         = 0;
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
            $profitChange[0] = [string](new-timespan –start $([datetime]$profitChange[0]) –end $([datetime]$(Get-Date -format U)));
            $profitChange[0] = $("{0} day(s) {1}h:{2}m:{3}s" -f $([timespan]$profitChange[0]).Days, $([timespan]$profitChange[0]).Hours, $([timespan]$profitChange[0]).Minutes, $([timespan]$profitChange[0]).Seconds);
        }
    
        #reads the 'main.txt' file
        [string[]]$fileArray = Get-Content -Path "$($filePath)main.txt";
        foreach ($_s In $fileArray) {
            #lines which starts with '#' are comments

            if (!($_s.StartsWith('#') -or [string]::IsNullOrEmpty($_s))) {
                if ($_s.StartsWith("apiKey")) {
                    $apiKey = $_s.Substring($_s.IndexOf('=') + 1);
                } elseif ($_s.StartsWith("hideOverallSection")) { 
                    $hideOverallSection = $_s.Substring($_s.IndexOf('=') + 1);
                } elseif ($_s.StartsWith("autorefreshRate")) {
                    $autoRefreshSec = [int]$_s.Substring($_s.IndexOf('=') + 1);
                } elseif ($_s.StartsWith("exchange")) {
                    $exchange = $_s.Substring($_s.IndexOf('=') + 1);
                } elseif ($_s.StartsWith("coin")) {
                    #retrieves the base coin ticker
                    $baseCoin = $_s.Substring($_s.IndexOf('=') + 1);
                } elseif ($_s.StartsWith("fiat")) {
                    #retrieves the fiat currency
                    if ($_s.Substring($_s.IndexOf('=') + 1).Length -gt 0) {
                        $fiatSymbol = $_s.Substring($_s.IndexOf('=') + 1);
                    } else { $fiatSymbol = "GBP"; }
                } else {
                    #retrieves the investment coin ticker
                    $_coinFrom       = $_s.Substring(1, $_s.IndexOf('/') - 1);
                    #retrieves the recevied coin ticker
                    $_coinTo         = $_s.Substring($_s.IndexOf('/') + 1, ($_s.IndexOf(']') - $_s.IndexOf('/')) - 1);
                    #retrieves the amount of the investment in 'baseCoin'
                    $_coinInvestment = $_s.Substring($_s.IndexOf(']') + 1, ($_s.IndexOf('>') - $_s.IndexOf(']')) - 1);
                    #retrieves the amount in 'baseCoin' recevied from the swap
                    $_coinAmountSwap = $_s.Substring($_s.IndexOf('>') + 1);

                    $pairCoin.Add(@($_coinFrom, $_coinTo, $_coinInvestment, $_coinAmountSwap, 0, 0, 0));
                    #the 4th index is the current value of the swapped coin in 'baseCoin'
                    #the 5th index is the current value of the swapped coin in fiat
                    #the 6th index is the profit change
                }
            }
        }


        # ======================= #
        #         GET CALL        #
        # ======================= #

        #retrieves the current fiat value for the 'baseCoin'
        $baseCoinFiatValue = (GetCoinPairInfo -fromTicker $baseCoin -toTicker $baseCoin -fiatTicker $fiatSymbol -ex $exchange)[1];
        
        for ($i = 0; $i -lt $pairCoin.Count; $i++) {
            #retrieves the current fiat and 'baseCoin' value for the swapped coin
            $_coinPairInfo = GetCoinPairInfo -fromTicker $pairCoin[$i][1] -toTicker $pairCoin[$i][0] -fiatTicker $fiatSymbol -ex $exchange;

            #baseCoin
            $pairCoin[$i][4] = $_coinPairInfo[0];
            #fiat
            $pairCoin[$i][5] = $_coinPairInfo[1];


            #calculate the total 'fiatValue' from all the swaps
            $fiatValueTotal += [decimal][math]::Round([decimal]$pairCoin[$i][3] * [decimal](GetCoinPairInfo -fromTicker $pairCoin[$i][1] -toTicker $baseCoin -fiatTicker $fiatSymbol -ex $exchange)[1], 2);

            #only increments the original amount with the swaps comed from the same 'baseCoin'
            if ($pairCoin[$i][0] -eq $baseCoin) {
                $baseCoinOriginalAmount += [decimal]$pairCoin[$i][2];
            }
        }

        # ======================= #
        #     OVERALL PROFIT      #
        # ======================= #

        if ($hideOverallSection -eq $false) {
            #calculates the new amont of 'baseCoin' gained from all the swaps
            $baseCoinNewAmount = [math]::Round($fiatValueTotal / $baseCoinFiatValue, 4);
            #converts the total profit in fiat for the 'baseCoin'
            #calculates the total % profit for the 'baseCoin'
            $baseCoinProfit = CalculatePercent -oAmount $baseCoinOriginalAmount -nAmount $baseCoinNewAmount -dRound 2;
            #calculates the profit change from the last time for the 'baseCoin' fiat value
            if ($profitChangeActive -eq $true) {
                #avoids dividing by 0
                if ($fiatValueTotal -ne 0 -and [decimal]$profitChange[1] -ne 0) {
                    $_fiatValueProfitChange = CalculatePercent -oAmount $([decimal]$profitChange[1]) -nAmount $fiatValueTotal -dRound 2;
                } else { $_fiatValueProfitChange = 0; }

                write-host -ForegroundColor Yellow "{Overall informations | Profit Difference Since (PDS) => $($profitChange[0])}"
            } else {
                write-host -ForegroundColor Yellow "{Overall informations}"
            }

        
            write-host -NoNewline "[1 $($baseCoin)]:         $baseCoinFiatValue [$fiatSymbol]`nOriginal Amount: $baseCoinOriginalAmount [$baseCoin]`nCurrent Amount:  $baseCoinNewAmount [$baseCoin] => $fiatValueTotal [$fiatSymbol] ";
            if ($fiatValueTotal -ge [decimal]$profitChange[1]) {
                if ($profitChangeActive -eq $true) {
                    write-host -NoNewline -ForegroundColor Green -BackgroundColor Black "PDS: $([math]::abs($_fiatValueProfitChange))%↑";
                }
            } else {
                if ($profitChangeActive -eq $true) {
                    write-host -NoNewline -ForegroundColor Red -BackgroundColor Black "PDS: $([math]::abs($_fiatValueProfitChange))%↓";
                }
            }
            write-host -NoNewline "`n`n";

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
                    $_profitChange = CalculatePercent -oAmount $([decimal]$profitChange[2]) -nAmount $baseCoinProfit -dRound 2;
                } else { $_profitChange = $baseCoinProfit; }

                #if the profit change is greater than the last profit will print the % in green otherwise in red
                if ($baseCoinProfit -ge [decimal]$profitChange[2]) {
                    write-host -ForegroundColor Green -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↑)";
                } else {
                    write-host -ForegroundColor Red   -BackgroundColor Black " (PDS: $([math]::abs($_profitChange))%↓)";
                }
            } else { write-host -NoNewline "`n"; }
        }


        # ======================= #
        # INDIVIDUAL PROFIT TABLE #
        # ======================= #

        #array which will contain the profit for each coin
        $_indNewProfit = New-Object decimal[] $pairCoin.Count;

        #prints a profit table
        if ($hideOverallSection -eq $true -and $profitChangeActive -eq $true) {
            write-host -ForegroundColor Yellow "Profit Difference Since (PDS) => $($profitChange[0])`n";
        }

        write-host -ForegroundColor Yellow -BackgroundColor Black "-                                              [INDIVIDUAL SWAPS]                                             -";
        write-host -ForegroundColor Yellow "|==============|============|=================|================|==============================================|";
        write-host -ForegroundColor Yellow "|     From     |     To     |      Profit     |      PDS       |                    Details                   |";
        write-host -ForegroundColor Yellow "|-------------------------------------------------------------------------------------------------------------|";

        for ($i = 0; $i -lt $pairCoin.Count; $i++) {
            $_indBaseCoinCurrentAmount = [decimal]$pairCoin[$i][3] * [decimal]$pairCoin[$i][4];
            $_indNewProfit[$i]         = CalculatePercent -oAmount $pairCoin[$i][2] -nAmount $_indBaseCoinCurrentAmount -dRound 2;

            #prints the 'From' coin ticker and the 'To' coin ticker section
            write-host -ForegroundColor Yellow -NoNewline "| $($pairCoin[$i][0].PadRight(13, ' '))| $($pairCoin[$i][1].PadRight(11, ' '))|";

            #prints the 'Profit' section
            #if the individual profit is greater than 0 will print the % in green otherwise in red
            if ($_indNewProfit[$i] -ge 0) {
                write-host -NoNewline -ForegroundColor Green -BackgroundColor Black ((' ' + [math]::abs($_indNewProfit[$i]) + '%').PadRight(16, ' ') + '↑');
            } else {
                write-host -NoNewline -ForegroundColor Red -BackgroundColor Black ((' ' + [math]::abs($_indNewProfit[$i]) + '%').PadRight(16, ' ') + '↓');
            }

            #prints a section separator between the 'Profit' and 'PDS' section
            write-host -NoNewline -ForegroundColor Yellow '|';

            #prints the 'PDS' section
            if ($profitChangeActive -eq $true) {
                #calculates the profit change from the last time
                #avoids dividing by 0
                if ([decimal]$profitChange[$i + 3] -ne 0) {
                    $_profitChange = CalculatePercent -oAmount $([decimal]$profitChange[$i + 3]) -nAmount $_indNewProfit[$i] -dRound 2;
                } else { $_profitChange = $_indNewProfit[$i]; }

                #if the profit change is greater than 0 will print the % in green otherwise in red
                if ($_indNewProfit[$i] -ge [decimal]$profitChange[$i + 3]) {
                    write-host -NoNewline -ForegroundColor Green -BackgroundColor Black ((' ' + [math]::abs($_profitChange) + '%').PadRight(15, ' ') + '↑');
                } else {
                    write-host -NoNewline -ForegroundColor Red   -BackgroundColor Black ((' ' + [math]::abs($_profitChange) + '%').PadRight(15, ' ') + '↓');
                }
            } else { 
                write-host -NoNewline -ForegroundColor Red -BackgroundColor Black ("      -//-      ")
            } 

            #prints the 'Details' section

            #prints the conversion infos
            write-host -NoNewline -ForegroundColor Yellow ((("| 1 " + $pairCoin[$i][1] + ' = ' + ([decimal]$pairCoin[$i][4]) + ' ' + $pairCoin[$i][0] + " => " + $pairCoin[$i][5] + ' ' + $fiatSymbol).PadRight(47, ' ')) + "|`n|");
            #prints the 'Original Amount'
            write-host -NoNewline -ForegroundColor Yellow (("| Original Amount:  " + $pairCoin[$i][2] + ' ' + $pairCoin[$i][0]).PadLeft(66 + $pairCoin[$i][0].Length + 17 + $pairCoin[$i][2].Length, ' ').PadRight(109, ' ') + "|`n|");
            #prints the 'Current Amount' highlighted
            write-host -NoNewline -ForegroundColor Yellow ('').PadRight(62, ' ');
            if ($_indBaseCoinCurrentAmount -ge $pairCoin[$i][2]) {
                write-host -NoNewline -ForegroundColor Green -BackgroundColor Black (("| Current Amount:   " + $_indBaseCoinCurrentAmount + ' ' + $pairCoin[$i][0]).PadRight(47, ' ') + "|`n");
            } else {
                write-host -NoNewline -ForegroundColor Red -BackgroundColor Black (("| Current Amount:   " + $_indBaseCoinCurrentAmount + ' ' + $pairCoin[$i][0]).PadRight(47, ' ') + "|`n");
            }
            #prints the 'Received Amount'
            write-host -NoNewline -ForegroundColor Yellow ('|').PadRight(63, ' ');
            write-host -NoNewline -ForegroundColor White -BackgroundColor Black (("| Received Amount:  " + $pairCoin[$i][3] + ' ' + $pairCoin[$i][1]).PadRight(47, ' ') + "|`n");

            #prints a separator between the coins
            write-host -NoNewline -ForegroundColor Yellow ((('|').PadRight(110, '-')) + "|`n");

        }

        # ======================= #
        #       TRACE FILE        #
        # ======================= #

        #updates the trace file with the current % profit to make a comparasion the next time
        $_traceFileValue  = "$(Get-Date -Format U)`n"; #timestamp from last verification
        $_traceFileValue += "$fiatValueTotal`n";
        $_traceFileValue += "$baseCoinProfit`n";
        for ($i = 0; $i -lt $pairCoin.Count; $i++) {
            $_traceFileValue += "$($_indNewProfit[$i])`n";
        }
        Set-Content -Path "$($filePath)profit.tr" -Value $_traceFileValue;


        RefreshExitLoop -autoRefreshSeconds $autoRefreshSec;
    } catch {
        Clear-Host;
        
        write-host -ForegroundColor Yellow -BackgroundColor Black "Something bad happened...`n`n";

        # This will happen when there's no internet connection
        if (!(Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected')) {
            write-host -ForegroundColor Red -BackgroundColor Black "Are you connected to the internet? :/`n`n";
        } else {
            write-host -ForegroundColor Red -BackgroundColor Black "Error: $($_.Exception)`n$($_.ScriptStackTrace)`n`n";
            write-host -ForegroundColor Yellow -BackgroundColor Black "Please send an e-mail to 'mutu.adi.marian@gmail.com' with the highlighted error above`n`n";
        }

        RefreshExitLoop;
    }
}

Stop-Process -Id $PID;
