<#
	Written By Patrick Löwe - 03/09/2018
	This will collect the endpoint that each device is pointed to 
	then export to logs
#>

$OutFile = ".\Logs\ServerName-$(((get-date).ToUniversalTime()).ToString("yyyMMddThhmmssZ")).csv"

New-Item -ItemType file -Path $OutFile | Out-Null # Create CSV
Add-Content $OutFile "Device Name, Server Name" # Add CSV headers

$inFile = ".\AllMachines.txt"

#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#---------------------------------------------------------------------------------------------------#

$AllDevices = (Get-Content $inFile)


ForEach ($DeviceName in $AllDevices) {
    
    $Test = Test-Connection -ComputerName $DeviceName -Count 1 -Quiet
    if($Test -eq "True"){
		
    [xml]$config = Invoke-Command -ComputerName $DeviceName -Credential $credential -ScriptBlock {
                        if(Test-Path "C:\Program Files (x86)\[PROGRAM_NAME]\[PROGRAM_EXE].config") { 
                            Get-Content "C:\Program Files (x86)\[PROGRAM_NAME]\[PROGRAM_EXE]config" 
                            } else { Get-Content "C:\Program Files\[PROGRAM_NAME]\[PROGRAM_EXE].config" }
                           } 
    $currentServerAddress = ($config.configuration.'system.serviceModel'.client.endpoint | Where {$_.contract -eq "ClientService.IClientService"}).Address
    
    Add-Content $OutFile "$DeviceName, $currentServerAddress"

	Write-Host "`n[PROGRAM_NAME] Server name is $currentServerAddress on $DeviceName.`n" -ForegroundColor "Green"
	
    }
	else {
		
        $DeviceOffline = "Device is UNREACHABLE"
        Add-Content $OutFile "$DeviceName, $DeviceOffline"
        Write-Host
		Write-Host "Client Offline" -ForegroundColor "Red"
	}
}