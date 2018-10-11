<#
	Created by Patrick Löwe 08/09/2018
	This Script will get the AUDIO LEVEL of all devices in allmachines.txt
	It requires the device username (with admin permissions) and password.
#>
#---------------------------------------------------------------------------------------------------#
$OutFile = ".\AudioLevel.csv"
if(Test-Path -Path $OutFile){Remove-Item $OutFile}
New-Item -ItemType file -Path $OutFile | Out-Null
Add-Content $OutFile "IP Address, Device Name, AudioLevel" # Add CSV headers
$AllDevices = ".\allmachines.txt"
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#---------------------------------------------------------------------------------------------------#
ForEach ($Device in $AllDevices) {
#	Test if device can be remoted onto
	$Test = Test-Connection -ComputerName $Device -Count 1 -Quiet
#	If it can connect, run the following
    if($Test -eq "True"){
	#	Get Device Name
	    $Name = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {$env:computername}
	#	Get Device Audio Level
		$AudioLevel = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Get-DefaultAudioDeviceVolume}
    #	Add results to CSV
		Add-Content $OutFile "$Device, $Name, $LCMSTATE, $Audiolevel"
		Write-Host "$Device - $Name : $Audiolevel" -BackgroundColor Black -ForegroundColor Cyan
        }
        else{
        Write-Host "`n$Device is offline`n" -BackgroundColor Black -ForegroundColor Red
        $MessageOFFline = "OFFLINE"
        Add-Content $OutFile "$Device, $MessageOFFline"
        }
    }