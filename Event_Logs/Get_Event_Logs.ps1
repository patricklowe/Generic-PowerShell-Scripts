<#	Written by Patrick Löwe		09/09/2018
	This script will Return:
	1) Top 100 Event Logs
	2) Event Logs past week, from today
	3) Event Logs with specified ID
#>
#	------------------------------------------------------------------------------------------	#
$OutFile = "Event_Logs.csv"
if(Test-Path -Path $OutFile){Remove-Item $OutFile}
New-Item -ItemType file -Path $OutFile | Out-Null
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
	Write-Host "Connected to $Device" -BackgroundColor Black -ForegroundColor Green
#	------------------------------------------------------------------------------------------	#
	Write-Host "`n1) Top 100 Event Logs" -BackgroundColor Black -ForegroundColor Yellow
	Write-Host "2) Event Logs previous 7 days" -BackgroundColor Black -ForegroundColor Yellow
	Write-Host "3) Event Logs with ID" -BackgroundColor Black -ForegroundColor Yellow
	Write-Host "Select Option (1,2,3): " -BackgroundColor Black -ForegroundColor Yellow -nonewline
	$Option = Read-Host
	if($Option.toLower() -eq "1")
	{
		$Result = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock{Get-WinEvent -MaxEvents 100 -FilterHashTable @{ LogName = "System"}} -erroraction 'silentlycontinue' | Export-CSV -Path $OutFile
		Write-Host "Eventlogs exported to $OutFile" -BackgroundColor Gray -ForegroundColor DarkGray
	}
	elseif($Option.toLower() -eq "2")
	{
		$StartDate = (get-date).AddDays(-7).Tostring("MM-dd-yyyy")
		Write-Host "Searching all System Logs from: $StartDate" -BackgroundColor Black -ForegroundColor Green
		$Result = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {param($StartDate) Get-WinEvent -FilterHashtable @{logname="System"; starttime=$StartDate}}-ArgumentList $StartDate -erroraction 'silentlycontinue'| Export-CSV -Path $OutFile 
		Write-Host "Eventlogs exported to $OutFile" -BackgroundColor Gray -ForegroundColor DarkGray
	}
	elseif($Option.toLower() -eq "3")
	{
		Write-Host "Enter EventLog ID: "  -BackgroundColor Black -ForegroundColor Yellow -nonewline
		$EventID = Read-Host
		$Result = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {param($EventID)   Get-WinEvent -FilterHashTable @{logname="System"; id = $EventID}} -ArgumentList $EventID -erroraction 'silentlycontinue' | Export-CSV -Path $OutFile
		Write-Host "Eventlogs exported to $OutFile" -BackgroundColor Gray -ForegroundColor DarkGray
	}
	else 
	{
		Write-Host "`nNo Logs recovered."-BackgroundColor Black -ForegroundColor Red
	}	
}
else{
	Write-Host "`n$Device is Offline`n" -BackgroundColor Black -ForegroundColor Red
	$MessageOFFline = "Device OFFLINE"
	Add-Content $OutFile "$Device, $MessageOFFline"
}
}