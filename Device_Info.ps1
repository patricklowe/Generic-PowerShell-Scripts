<#	Written by Patrick Löwe		08/09/2018
	This script will return all machine info, PowerShell and SQL
#>
#---------------------------------------------------------------------------------------------------#
$OutFile1 = ".\Results_PS.csv"
if(Test-Path -Path $OutFile1){Remove-Item $OutFile1}
New-Item -ItemType file -Path $OutFile1 | Out-Null
$OutFile2 = ".\Results_SQL.csv"
if(Test-Path -Path $OutFile2){Remove-Item $OutFile2}
New-Item -ItemType file -Path $OutFile2 | Out-Null
if(Test-Path -Path ".\Results_Info.csv"){Remove-Item ".\Results_Info.csv"}
Write-Host "`nEnter Device IP: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$DeviceID = Read-Host

#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$password = Read-Host -AsSecureString
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$username = Read-Host 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#---------------------------------------------------------------------------------------------------#
#	Setup SQL Details
Write-Host "Enter SQL Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
Write-Host "Enter SQL Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
#	 Get password as masked input
$Password = Read-Host -AsSecureString
#	 Convert to allow SQL to read password
$Password =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
#	SQL Server
Write-Host "Enter SQL Server Instance: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$ServerInstance = Read-Host
#	 SQL Database
Write-Host "Enter SQL Database: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Database = Read-Host
#---------------------------------------------------------------------------------------------------#
$DeviceInfo = @"
DECLARE @DeviceIP nchar(50)= 
(select IPAddress from DeviceMetadata
where IPAddress = '$DeviceID')
select DISTINCT 'Device Info' as 'Query',
	ClientID, 
	LastPingTime, 
	SoftwareVersion, 
	MacAddress 
from DeviceMetadata where IPAddress = @DeviceIP
"@
#---------------------------------------------------------------------------------------------------#
#	Get Device Info, PowerShell
    $UpTime = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(gcim Win32_OperatingSystem).LastBootUpTime}
	$OSys = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-WmiObject Win32_OperatingSystem).Name}
	$OArch = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-WmiObject Win32_OperatingSystem).OSArchitecture}
	$Model = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-WmiObject -Class:Win32_ComputerSystem).Model}
	$Audio = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {Get-DefaultAudioDeviceVolume}
	$Culture = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {Get-UICulture}
	$AvailableSpace = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {uwfmgr Overlay Get-AvailableSpace}
	$Config = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {uwfmgr Get-Config}
	$Partition = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {Get-Partition}
	$disk = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {Get-WmiObject win32_logicaldisk -ComputerName localhost -filter "deviceid='V:'"}
	$freespace = [system.math]::round((($disk.freespace) / 1GB))
	$Servicing = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {uwfmgr servicing get-config}
	Write-Host "Last Reboot: $UpTime `nOperating System: $OSys `nArchitecture: $OArch `nModel: $Model `nAudio Level: $Audio `nCulture: $Culture" -BackgroundColor Black -ForegroundColor Green
#	------------------------------------------------------------------------------------------	#
	Write-Host "Checking $Database"
	$ResultSQL = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $DeviceInfo
	$ResultSQL | Export-csv -Path $OutFile2 -Append -Force
	Add-Content $OutFile1 "Device: $DeviceID `r`nLast Reboot: $UpTime `r`nOperating System: $OSys `r`nArchitecture: $OArch `r`nModel: $Model `r`nAudio Level: $Audio `r`nCulture: $Culture `r`nAvailableSpace: $AvailableSpace `r`n	UWF Config: $Config `r`nPartition: $Partition `r`n	Disk Space: $disk `r`nfreespace: $freespace `r`n Servicing: $Servicing"
#	------------------------------------------------------------------------------------------	#
	Write-Host "`nMerging Results..." -BackgroundColor Black -ForegroundColor Green
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
    Add-Content ".\Results_Info.csv" $CopiedData
#	Appends a new line between queries for easier reading
	Add-Content ".\Results_Info.csv" -Value ""
    }

#	------------------------------------------------------------------------------------------	#
#	Delete the separate query results files
if(Test-Path -Path $OutFile1){Remove-Item $OutFile1}
if(Test-Path -Path $OutFile2){Remove-Item $OutFile2}
#	------------------------------------------------------------------------------------------	#
Write-Host "`nOpen Results Folder (Y/N): " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Option = Read-Host
if($Option.toLower() -eq "y")
{
	ii .
}
else 
{
	Write-Host "`nResults exported to "-BackgroundColor Black -ForegroundColor Green -nonewline
	Write-Host "$OutFile`n" -BackgroundColor Black -ForegroundColor Red
}