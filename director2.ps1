############### VARIABLES ###############

$inputfilename='input.txt'
$outputfilename='output.txt'
$directory=''    # Leave blank for current working directory
$keypressdelay = 40
$realitydelay = 40
$editor = 'notepad'
$tablength = 8

#$true = 1
#$false = 0
$run = $true

$debug = $false

$continue = $false
$preclose=$true

$orderOfSections = New-Object System.Collections.Generic.List[System.Object] #@()
$lengthOfSections = New-Object System.Collections.Generic.List[System.Object] #@()
$instanceOfSection = New-Object System.Collections.Generic.List[System.Object] 

$length=0
$global:numberOfSections=0

$prevline = ""
$linenum=1
$lineText=""
$oldSectionLocation=0
$newSectionLocation=0
$readSectionNumber=0
$direction="up"
$distance=0
$Tab = [char]9

$somelines=@()
$i=0
while($i -lt $numlinestocompare+1){
    $somelines += ""
    $i=$i+1
}

if ($directory -eq '') {
    $directory=$PSScriptRoot+"\"
}


############### FUNCTIONS ###############

function Set-WindowStyle {
param(
    [Parameter()]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 
                 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 
                 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    $Style = 'SHOW',
    [Parameter()]
    $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
)
    $WindowStates = @{
        FORCEMINIMIZE   = 11; HIDE            = 0
        MAXIMIZE        = 3;  MINIMIZE        = 6
        RESTORE         = 9;  SHOW            = 5
        SHOWDEFAULT     = 10; SHOWMAXIMIZED   = 3
        SHOWMINIMIZED   = 2;  SHOWMINNOACTIVE = 7
        SHOWNA          = 8;  SHOWNOACTIVATE  = 4
        SHOWNORMAL      = 1
    }
    Write-Verbose ("Set Window Style {1} on handle {0}" -f $MainWindowHandle, $($WindowStates[$style]))

    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}


function pause ($message){
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}


function Write-Line{
 param ($lineText)
    $lineText.ToCharArray() | ForEach-Object {
    
        if ( $_ -eq '+' -or $_ -eq '^' -or $_ -eq '%' -or $_ -eq '~'){
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{$_}")
            Start-Sleep -Milliseconds $realitydelay
            #Write-Output $_
        } elseif ( $_ -eq '-' -or $_ -eq '_' -or $_ -eq '=' -or $_ -eq '!' -or $_ -eq '@' -or $_ -eq '#' -or $_ -eq '$' -or $_ -eq '*' -or $_ -eq '&' -or $_ -eq ':' -or $_ -eq ';' -or $_ -eq "'" -or $_ -eq '"' -or $_ -eq '\' -or $_ -eq '/' -or $_ -eq '?' -or $_ -eq ',' -or $_ -eq '.' ){
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys($_)
            Start-Sleep -Milliseconds $realitydelay

        } elseif ($_ -eq $Tab){
            Write-Output "tabbing"
            foreach($i in 1..$tablength){
                $wshell.SendKeys(" ")
            }

        } elseif ($_ -eq '{' -And $preclose -eq $true){
            $wshell.SendKeys("{{}")
            $wshell.SendKeys("{ENTER}")
            $wshell.SendKeys("{}}")
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{LEFT}")
            $wshell.SendKeys("{LEFT}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq '}' -And $preclose -eq $true){
            $wshell.SendKeys("{DEL}")
            $wshell.SendKeys("{RIGHT}")
            Start-Sleep -Milliseconds $realitydelay

        } elseif ($_ -eq '[' -And $preclose -eq $true){
            $wshell.SendKeys("{[}")
            $wshell.SendKeys("{]}")
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{LEFT}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq ']' -And $preclose -eq $true){
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{RIGHT}")
            #Start-Sleep -Milliseconds $realitydelay/2

        } elseif ($_ -eq '(' -And $preclose -eq $true){
            $wshell.SendKeys("{(}")
            $wshell.SendKeys("{)}")
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{LEFT}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq ')' -And $preclose -eq $true){
            Start-Sleep -Milliseconds $realitydelay
            $wshell.SendKeys("{RIGHT}")
            #Start-Sleep -Milliseconds $realitydelay/2




        } elseif ($_ -eq '{' -And $preclose -eq $false){
            $wshell.SendKeys("{{}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq '}' -And $preclose -eq $false){
            $wshell.SendKeys("{}}")
            Start-Sleep -Milliseconds $realitydelay

        } elseif ($_ -eq '[' -And $preclose -eq $false){
            $wshell.SendKeys("{[}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq ']' -And $preclose -eq $false){
            $wshell.SendKeys("{]}")
            Start-Sleep -Milliseconds $realitydelay

        } elseif ($_ -eq '(' -And $preclose -eq $false){
            $wshell.SendKeys("{(}")
            Start-Sleep -Milliseconds $realitydelay
        } elseif ($_ -eq ')' -And $preclose -eq $false){
            $wshell.SendKeys("{)}")
            Start-Sleep -Milliseconds $realitydelay
        
        
        
        } else {
            $wshell.SendKeys($_)
        }
        Start-Sleep -Milliseconds $keypressdelay
    }

    #$wshell.SendKeys("{ENTER}")
   }


function Convert-Script{
    Remove-Item –path $directory$outputfilename
    
    $Tab = [char]9
    $i = 1
    foreach($line in Get-Content $directory$inputfilename) {
        Write-Output $i$tab$line
        Add-Content $directory$outputfilename $tab$line
        $i=$i+1
    }
}


# Read Entire script linearly and populate arrays.
function Populate-Arrays{
    Write-Output "Populting Arrays..."
    foreach ($line in Get-Content $directory$outputfilename) {
        $parts = $line.split($Tab)
        $readSectionNumber = $parts[0]
        $readSectionNumber = $readSectionNumber -replace '\D+'
        $lineText = $parts[1]
        #Write-Output "$($linenum) $($readSectionNumber) $($parts[0][0])"
    
        
        if ($continue -eq $true){
            #Write-Output "Continuting"
            $length = $length + 1
        }


        if ($readSectionNumber -match '\d' -And $continue -eq $false -And $parts[0][0] -ne "/"){
                        #Write-Output "New Line"
            $orderOfSections.Add($readSectionNumber) # += $readSectionNumber
            $length = 1

            if ($parts[0] -like '*>*') { 
                $continue = $true
                #Write-Output "Start Continuting"
            } else {
                
                $lengthOfSections.Add(1) # += $length
            }
        }
    

        if ($parts[0] -like '*<*') { 
            $continue = $false
            #Write-Output "Stop Continuting"
            $lengthOfSections.Add($length) # += $length
            $length = 0

            #pause "Press okay to continue"
        }

    }

    $global:numberOfSections=$orderOfSections.Count
    Write-Output "Total Number of Sections: $($global:numberOfSections)"
    $i=0
    while ($i -lt $global:numberOfSections){
        Write-Output "$($orderOfSections[$i]) $($lengthOfSections[$i])"
        $i=$i+1
    }

}


############### MAIN ###############

Convert-Script
Start-Process $editor $directory$outputfilename

pause "Script Converted. Please annotate the file: $($directory)$($outputfilename)"


Populate-Arrays
Write-Output "Annotation read and Arrays Populated"
#pause "Arrays Populated"

pause "Right now is a good time to start screen recording or open comparison window. Please do not touch anything until it is done."



Start-Process $editor
Start-Sleep -s 1


(Get-Process -Name notepad).MainWindowHandle | foreach { Set-WindowStyle MAXIMIZE $_ }


$wshell = New-Object -ComObject wscript.shell;

#$wshell.SendKeys('asdf')
#'WASDasdfasdf'.ToCharArray() | ForEach-Object {
#$wshell.SendKeys($_)
#Start-Sleep -Milliseconds $keypressdelay
#}
#$wshell.SendKeys("{ENTER}")



while ($run -eq $true){
    #pause "Starting"
    foreach($line in Get-Content $directory$outputfilename) {
            
        $Tab = [char]9
        #$parts = $line.split($Tab)
        $parts = $line -split $Tab,2
        $readSectionNumber = $parts[0]
        $readSectionNumber = $readSectionNumber -replace '\D+'
        $lineText = $parts[1]
        #Write-Output "$($linenum) $($readSectionNumber) $($parts[0][0])"
        #Write-Output $lineText


        if ($parts[0] -like "-"){
            $preclose = $false
            Write-Output "no preclose"
        } else {
            $preclose = $true
        }
        
        if ($continue -eq $true){
            #Write-Output "Continuting"
            Start-Sleep -Milliseconds $realitydelay
            if ($debug -eq $false){Write-Line $lineText} else {Write-Output $lineText}
            $wshell.SendKeys("{ENTER}")
            Start-Sleep -Milliseconds $realitydelay
        }


        if ($linenum -eq $readSectionNumber -And $continue -eq $false -And $parts[0][0] -ne "/"){
            
            $i=0
            while($i -lt $global:numberOfSections){
                if ($orderOfSections[$i] -eq $readSectionNumber){
                    $newSectionLocation = $i
                }
                $i=$i+1
            }



            $i=0
            #Write-Output "Number Of Sections: $($global:numberOfSections)"
            while($i -lt $global:numberOfSections){
                if ($orderOfSections[$i] -eq $readSectionNumber -1){
                    $oldSectionLocation = $i
                    if ($oldSectionLocation -lt $newSectionLocation){
                        $direction = "down"
                        Write-Output $direction
                    } else {
                        $direction = "up"
                        Write-Output $direction
                        #$wshell.SendKeys("{DEL}")
                        #$wshell.SendKeys("{UP}")
                    }
                    #pause "Direction $($direction)"
                }
                $i =$i+1
            }

            #pause "Going $($direction) from section $($readSectionNumber-1) ($($oldSectionLocation)) to $($readSectionNumber) ($($newSectionLocation))"


            $distance = 0
            $i=$oldSectionLocation
            if ($direction -eq "down") { 
                while ($i -lt [int]$newSectionLocation) {
                    if ([int]$orderOfSections[$i] -lt [int]$readSectionNumber-1){
                        Write-Output "Adding length: $($lengthOfSections[$i])"
                        $distance = $distance + $lengthOfSections[$i]
                    }
                
                    $i=$i+1
                }
            }

            if ($direction -eq "up") { 
                while ($i -gt [int]$newSectionLocation) {
                    if ([int]$orderOfSections[$i] -lt [int]$readSectionNumber){
                        Write-Output "Comparing $($orderOfSections[$i].GetType().FullName) $($readSectionNumber.GetType().FullName) on $($i)"

                        Write-Output "Adding length: $($lengthOfSections[$i]) of section $($orderOfSections[$i])"
                        $distance = $distance + $lengthOfSections[$i]
                    } else {
                        Write-Output "nope"
                    }
                
                    $i=$i-1
                }
            }


            Write-Output $direction
            Write-Output $distance
            #pause "Distance $($distance)"



            $i=0
            if ($distance -ne -1){
                
                if ($direction -eq "up"){
                    $wshell.SendKeys("{HOME}")
                    while ($i -lt $distance-1){
                        $wshell.SendKeys("{UP}")
                        Start-Sleep -Milliseconds $realitydelay
                        $i=$i+1
                    }
                    $wshell.SendKeys("{ENTER}")
                    $wshell.SendKeys("{UP}")
                } elseif ($direction -eq "down"){
                    #pause "its going down!"
                    $wshell.SendKeys("{ENTER}")
                    $wshell.SendKeys("{DEL}")
                    $wshell.SendKeys("{UP}")
                    while ($i -lt $distance+1){
                        $wshell.SendKeys("{DOWN}")
                        Start-Sleep -Milliseconds $realitydelay
                        $i=$i+1
                    }
                    $wshell.SendKeys("{ENTER}")
                    $wshell.SendKeys("{UP}")
                } 
 
            }



            $linenum = $linenum+1
            #Write-Output "Match"
            if ($debug -eq $false){Write-Line $lineText} else {Write-Output $lineText}


            

            if ($parts[0] -like '*>*') { 
                $continue = $true
                Start-Sleep -Milliseconds $realitydelay
                $wshell.SendKeys("{ENTER}")
                Start-Sleep -Milliseconds $realitydelay
                Write-Output "Start Continuting"

            }

        }
    

        if ($parts[0] -like '*<*' -And $continue -eq $true) { 
            $continue = $false
            $wshell.SendKeys("{BS}")
            Write-Output "Stop Continuting"
            break
            #$linenum = $linenum+1
            #pause "Press okay to continue"
        }
  
        #pause "Press okay to continue"
   
    
    }

    if ($linenum -gt $numberOfSections) {
        $run = $false
        break
    }


    if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
        Write-Host "Exiting now, don't try to stop me...." -Background DarkRed
        $run = $false
        break;
    }


       
}    
    
 
 Start-Sleep -Milliseconds 1000

 pause "All Done"


