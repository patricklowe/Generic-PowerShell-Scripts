<#	Written by Patrick Löwe		08/09/2018
	This script will return FRS Version and Install date, and Image Version.
	No Output file, highlight powershell window (click & drag) then right click to copy info if needed
#>
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device IP: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$DeviceID = Read-Host
$FRS_Version = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\[PROGRAM_NAME]\FRS').Version}
$FRS_Installed = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\[PROGRAM_NAME]\FRS').Installed}
$Image_Version = Invoke-Command -ComputerName $DeviceID -Credential $credential -ScriptBlock {(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\[PROGRAM_NAME]\IMAGE').Version}

Write-Host "`nFRS Version: $FRS_Version" -BackgroundColor Black -ForegroundColor Cyan
Write-Host "FRS Installed: $FRS_Installed" -BackgroundColor Black -ForegroundColor Cyan
Write-Host "Image Version: $Image_Version" -BackgroundColor Black -ForegroundColor Cyan