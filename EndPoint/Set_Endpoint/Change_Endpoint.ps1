Import-Module -Name c:\Drop\Tools\connectivity_module -Force

<#
	Written By Patrick Löwe - 03/09/2018
	This will change the endpoint that each device is pointed to 
	based on the information provided.
#>

$ConfigFile = "C:\Program Files (x86)\[PROGRAM_NAME]\[PROGRAM_EXE].config"

if(!(Test-Path $ConfigFile)){
	$ConfigFile = "C:\Program Files\[PROGRAM_NAME]\[PROGRAM_EXE].config"
}
 
If (Test-Path $ConfigFile){
		
	$update = $false
#	Get New server name
	Write-Host 'Please enter the new server name: '-BackgroundColor Black -ForegroundColor Yellow -nonewline
	$ServerName = Read-Host
	ForEach ($DeviceName in $AllDevices) {
    
    $Test = Test-Connection -ComputerName $DeviceName -Count 1 -Quiet
    if($Test -eq "True"){
		(Get-Content $ConfigFile) | ForEach-Object { $_ -replace "http://.*?\/" , "http://$ServerName/" } | Set-Content $ConfigFile
		Write-Host "`nClient configuration updated to server $Servername successfully.`n" -ForegroundColor "Green"
	
	}
	else {
		Write-Host "Could not connect to '$($ServerName)'" -ForegroundColor "Red"
		$option = Read-Host("Do you wish to proceed with update? Enter 'Y' to update or 'N' to abort.")		
		$update = ($option -eq "y" -or $option -eq "Y")
	}
	else {
		Write-Host
		Write-Host "Server Endpoint NOT changed" -ForegroundColor "Red"
	}
	}
	else{
Write-Warning "`nClient not found on this device`n" 
}
`}
Read-Host 'Press Enter to continue...'