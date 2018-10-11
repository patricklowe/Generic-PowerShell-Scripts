<#	Written by Patrick Löwe		27/08/2018
	This script will Return the date/time/culture for all devices in 'allmachines.txt'
#>
#	------------------------------------------------------------------------------------------	#
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
	$TimeZoneBefore = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {tzutil /g}
	Write-Host "Connected to $Device" -BackgroundColor Black -ForegroundColor Green
#	------------------------------------------------------------------------------------------	#
	Write-Host "`n1) UCSF - Pacific Standard Time" -BackgroundColor Black -ForegroundColor Yellow
	Write-Host "2) NYU  - Eastern Standard Time" -BackgroundColor Black -ForegroundColor Yellow
	Write-Host "Select TimeZone(1,2): " -BackgroundColor Black -ForegroundColor Yellow -nonewline
	$Option = Read-Host
	if($Option.toLower() -eq "1")
	{
		Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {tzutil /s 'Pacific Standard Time'}
	}
	elseif($Option.toLower() -eq "2")
	{
		Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {tzutil /s 'Eastern Standard Time'}
	}
	else 
	{
		Write-Host "`nNo Changes were made."-BackgroundColor Black -ForegroundColor Red
	}
#	------------------------------------------------------------------------------------------	#
	$TimeZoneAfter = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {tzutil /g}
	Write-Host "$Device was $TimeZoneBefore, changed to $TimeZoneAfter" -BackgroundColor Black -ForegroundColor Green
	}
else{
	Write-Host "`n$Device is Offline`n" -BackgroundColor Black -ForegroundColor Red
	$MessageOFFline = "Device OFFLINE"
	Add-Content $OutFile "$Device, $MessageOFFline"
}
}