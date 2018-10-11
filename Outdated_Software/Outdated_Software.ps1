<#
	Created by Patrick Löwe 15/09/2018
	This Script will get all devices in outdated and current software version
	Then export it to SoftwareVersion.csv
#>
#---------------------------------------------------------------------------------------------------#
$OutFile = ".\SoftwareVersion.csv"
if(Test-Path -Path $OutFile){Remove-Item $OutFile}
New-Item -ItemType file -Path $OutFile | Out-Null
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Current Version: " -nonewline -BackgroundColor Black -ForegroundColor Yellow
$SVersion = Read-Host
#---------------------------------------------------------------------------------------------------#
#	Setup SQL Details
Write-Host "Enter SQL Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter SQL Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host -AsSecureString
#	 Get Server Instance
Write-Host "Enter SQL Server Instance: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$ServerInstance = Read-Host
#	Get SQL Database Name
Write-Host "Enter SQL Database: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Database = Read-Host
#---------------------------------------------------------------------------------------------------#
$Count_Current = @"
SELECT m.SoftwareVersion, COUNT(*) FROM Client c JOIN DeviceMetadata m on c.ClientID = m.ClientID GROUP BY m.SoftwareVersion ORDER BY m.SoftwareVersion
"@

$Current = @"
SELECT c.Name, d.SoftwareVersion,d.IPAddress as 'Current clients' FROM Client c INNER JOIN DeviceMetadata d ON c.ClientID = d.ClientID ORDER BY c.Name
"@

$Outdated_Online = @"
SELECT c.Name, d.SoftwareVersion,d.IPAddress as 'Out of date clients and online' FROM Client c INNER JOIN DeviceMetadata d ON c.ClientID = d.ClientID WHERE d.SoftwareVersion not like '$SVersion%' AND DATEDIFF(mi, d.LastPingTime, CURRENT_TIMESTAMP) < 30 ORDER BY c.Name
"@

$Outdated_Offline = @"
SELECT c.Name, d.SoftwareVersion,d.IPAddress as 'Out of date clients and offline' FROM Client c INNER JOIN DeviceMetadata d ON c.ClientID = d.ClientID WHERE d.SoftwareVersion != '$SVersion' AND DATEDIFF(mi, d.LastPingTime, CURRENT_TIMESTAMP) > 30 ORDER BY c.Name
"@
#---------------------------------------------------------------------------------------------------#
Write-Host "`nQuerying " -BackgroundColor Black -ForegroundColor Cyan -nonewline
Write-Host "$ServerInstance\$Database " -BackgroundColor Black -ForegroundColor Red -nonewline
Write-Host "using " -BackgroundColor Black -ForegroundColor Cyan -nonewline
Write-Host "$Username" -BackgroundColor Black -ForegroundColor Red
$Result1 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Count_Current
$Result2 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Current
$Result3 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Outdated_Online
$Result4 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Outdated_Offline
#	------------------------------------------------------------------------------------------	#
$Result1 | Export-csv -Path ".\Count.csv" -Append -Force
$Result2 | Export-csv -Path ".\Current.csv" -Append -Force
$Result3 | Export-csv -Path ".\Online.csv" -Append -Force
$Result4 | Export-csv -Path ".\Offline.csv" -Append -Force
#	------------------------------------------------------------------------------------------	#
Write-Host "`nMerging Results..." -BackgroundColor Black -ForegroundColor Cyan
#	This will skip the first line within each of the 8 queries, do not change. It skips adding the '#TYPE System.Data.DataRow' into the Results file
$SkipLine = $true
#	Gather all data in all files at below location (with csv file type), then append onto results file
Get-ChildItem ".\*.csv" | foreach {
    $FilePath = $_
    $lines =  $lines = Get-Content $FilePath  
    $CopiedData = switch($SkipLine) {
           $true  {$lines}
           $false {$lines | Select -Skip 1}

    }
    $SkipLine = $false
    Add-Content ".\Outdated_Software.csv" $CopiedData
#	Appends a new line between queries for easier reading
	Add-Content ".\Outdated_Software.csv" -Value ""
    }
#	------------------------------------------------------------------------------------------	#
#	Delete the separate query results files
if(Test-Path -Path ".\Count.csv"){Remove-Item ".\Count.csv"}
if(Test-Path -Path ".\Current.csv"){Remove-Item ".\Current.csv"}
if(Test-Path -Path ".\Online.csv"){Remove-Item ".\Online.csv"}
if(Test-Path -Path ".\Offline.csv"){Remove-Item ".\Offline.csv"}
if(Test-Path -Path ".\SoftwareVersion.csv"){Remove-Item ".\SoftwareVersion.csv"}

