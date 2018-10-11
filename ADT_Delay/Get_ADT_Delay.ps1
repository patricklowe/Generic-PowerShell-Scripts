<#
	Written By Patrick Löwe - 03/09/2018
	This script will get the delay in processing mesasges from ADT and export results to CSV file.
	This script has been slightly altered for data privacy.
#>
#	 Setup output file
$Results = ".\delay.csv"
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
#	Date, start point of delays, will always be from midnight
$Date = (Get-Date).ToString("yyyy-MM-dd")
#	Number of rows to return
Write-Host "How many rows: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Amount = Read-Host
#	------------------------------------------------------------------------------------------	#
$ADTDelay = @"
select top $amount DATEDIFF(MINUTE, MessageTime, ProcessedTime) as 'Delay(Mins)', MessageTime, ProcessedTime, MessageType from EventLogADT 
where DATEDIFF(MINUTE, MessageTime, ProcessedTime) > 2 and MessageTime between '$Date 00:00:00' and getdate()
order by MessageTime desc;
"@
#	------------------------------------------------------------------------------------------	#
$Delay = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $ADTDelay
#	Delete pre-existing file
if(Test-Path -Path $Results){Remove-Item $Results}
#	 Export current delay results
$Delay | Export-csv -Path $Results -Append -Force
#	Delete unnecessary header
(Get-Content $Results | Select-Object -Skip 1) | Set-Content $Results
#	Load Delay into Powershell
Import-csv $Results
#	Delete results, prevent clogging
if(Test-Path -Path $Results){Remove-Item $Results}