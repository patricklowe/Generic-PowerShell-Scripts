<#	Written by Patrick Löwe		27/08/2018
	This script will Return the date/time/culture for all devices in 'allmachines.txt'
#>
#	------------------------------------------------------------------------------------------	#
$OutFile = "Date_Time_Culture_Results.csv"
if(Test-Path -Path $OutFile){Remove-Item $OutFile}
New-Item -ItemType file -Path $OutFile | Out-Null
Add-Content $OutFile "Device Name, Date, Culture, TimeZone" 
$inFile = ".\allmachines.txt"
$AllDevices = (Get-Content $InFile)
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#	------------------------------------------------------------------------------------------	#
ForEach ($Device in $AllDevices) {
	$Test = Test-Connection -ComputerName $Device -Count 1 -Quiet
if($Test -eq "True"){
	Write-Host "Connected to $Device" -BackgroundColor Black -ForegroundColor Yellow
	$Date = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Get-Date}       
	$Culture = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Get-UICulture}       
	$TimeZone = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {tzutil /g}
	Add-Content $OutFile "$Device, $Date, $Culture, $TimeZone"
	Write-Host "Device: " -nonewline
	Write-Host "$Device" -BackgroundColor Black -ForegroundColor Green
	Write-Host "Date: " -nonewline
	Write-Host "$Date" -BackgroundColor Black -ForegroundColor Green
	Write-Host "Culture: " -nonewline
	Write-Host "$Culture" -BackgroundColor Black -ForegroundColor Green
	Write-Host "TimeZone: " -nonewline
	Write-Host "$TimeZone" -BackgroundColor Black -ForegroundColor Green
	}
else{
	Write-Host "`n$Device is Offline`n" -BackgroundColor Black -ForegroundColor Red
	$MessageOFFline = "Device OFFLINE"
	Add-Content $OutFile "$Device, $MessageOFFline"
}
}